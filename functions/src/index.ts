import * as admin from "firebase-admin";
import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { getAuth } from "firebase-admin/auth";

admin.initializeApp();

// ✅ Use Firebase Secrets properly for v2
const ELEVENLABS_KEY = defineSecret("ELEVENLABS_KEY");

async function verifyFirebaseAuth(req: any): Promise<string> {
  const authHeader = req.headers.authorization || "";
  const match = authHeader.match(/^Bearer (.+)$/);
  if (!match) {
    const err: any = new Error("Missing bearer token");
    err.status = 401;
    throw err;
  }

  const idToken = match[1];
  try {
    const decoded = await getAuth().verifyIdToken(idToken);
    return decoded.uid;
  } catch (e) {
    const err: any = new Error("Invalid token");
    err.status = 401;
    throw err;
  }
}

function normalizeLang(lang: any): "en" | "te" | null {
  if (typeof lang !== "string") return null;
  const l = lang.trim().toLowerCase();
  if (l === "en" || l === "te") return l;
  return null;
}

async function rateLimit(uid: string) {
  const ref = admin.firestore().doc(`users/${uid}/rate_limits/parentVoiceSpeak`);
  const now = Date.now();
  const windowMs = 60 * 1000;
  const maxReq = 10;

  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.exists ? snap.data()! : {};
    const resetAt = typeof data.resetAt === "number" ? data.resetAt : 0;
    const count = typeof data.count === "number" ? data.count : 0;

    if (resetAt > now) {
      if (count >= maxReq) {
        const err: any = new Error("Too many requests");
        err.status = 429;
        throw err;
      }
      tx.set(ref, { count: count + 1 }, { merge: true });
    } else {
      tx.set(ref, { count: 1, resetAt: now + windowMs }, { merge: true });
    }
  });
}


export const parentVoiceSpeak = onRequest(
  {
    cors: true,
    timeoutSeconds: 300,
    // ✅ Ensures secret is available at runtime
    secrets: [ELEVENLABS_KEY],
  },
  async (req, res) => {
    // Preflight
    if (req.method === "OPTIONS") {
      res.set("Access-Control-Allow-Methods", "POST");
      res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
      res.set("Access-Control-Max-Age", "3600");
      res.status(204).send("");
      return;
    }

    // ✅ POST only
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    try {
      // ✅ Auth
      const uid = await verifyFirebaseAuth(req);
await rateLimit(uid);
      // ✅ Validate body
      const body = req.body ?? {};
      const { storyId, pageIndex, lang, text, voiceId } = body;

      if (typeof storyId !== "string" || storyId.trim().length === 0) {
        res.status(400).json({ error: "Invalid storyId" });
        return;
      }

      const pageIdxNum = Number(pageIndex);
      if (!Number.isInteger(pageIdxNum) || pageIdxNum < 0 || pageIdxNum > 500) {
        res.status(400).json({ error: "Invalid pageIndex" });
        return;
      }

      const normLang = normalizeLang(lang);
      if (!normLang) {
        res.status(400).json({ error: "Invalid lang (must be 'en' or 'te')" });
        return;
      }

      if (typeof voiceId !== "string" || voiceId.trim().length < 3) {
        res.status(400).json({ error: "Invalid voiceId" });
        return;
      }

      if (typeof text !== "string") {
        res.status(400).json({ error: "Invalid text" });
        return;
      }

      const cleanText = text.trim();
      if (cleanText.length === 0) {
        res.status(400).json({ error: "Empty text" });
        return;
      }

      // ✅ Abuse/billing guardrails
      if (cleanText.length > 1000) {
        res.status(413).json({ error: "Text too long (max 1000 chars)" });
        return;
      }

      // ✅ Ensure secret exists
      const elevenKey = ELEVENLABS_KEY.value();
      if (!elevenKey) {
        res.status(500).json({ error: "Server not configured (missing ELEVENLABS_KEY)" });
        return;
      }

      // ✅ Cache
      const cacheKey = `${voiceId.trim()}_${storyId.trim()}_${pageIdxNum}_${normLang}`;
      const cacheDocRef = admin.firestore().doc(`users/${uid}/voice_cache/${cacheKey}`);
      const cacheDoc = await cacheDocRef.get();

      if (cacheDoc.exists) {
        const data = cacheDoc.data() || {};
        if (typeof data.audioUrl === "string" && data.audioUrl.length > 0) {
          res.json({ audioUrl: data.audioUrl, cached: true });
          return;
        }
        // If cache doc is malformed, fall through and regenerate.
      }

      // ✅ Call ElevenLabs
      const ttsResp = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voiceId.trim()}`, {
        method: "POST",
        headers: {
          "xi-api-key": elevenKey,
          "Content-Type": "application/json",
          Accept: "audio/mpeg",
        },
        body: JSON.stringify({
          text: cleanText,
          model_id: "eleven_multilingual_v2",
          voice_settings: { stability: 0.4, similarity_boost: 0.75 },
        }),
      });

      if (!ttsResp.ok) {
        const detail = await ttsResp.text();
        // 502: upstream provider failure
        res.status(502).json({ error: "ElevenLabs TTS failed", detail });
        return;
      }

      // ✅ Save to Storage
      const audioBuffer = Buffer.from(await ttsResp.arrayBuffer());
      // optional guard: reject tiny/empty audio
      if (audioBuffer.length < 200) {
        res.status(502).json({ error: "Invalid audio returned from ElevenLabs" });
        return;
      }

      const bucket = admin.storage().bucket();
      const storagePath = `users/${uid}/voice_cache/${voiceId.trim()}/${storyId.trim()}/page_${pageIdxNum}_${normLang}.mp3`;
      const file = bucket.file(storagePath);

      await file.save(audioBuffer, { contentType: "audio/mpeg" });

      // ✅ Signed URL (30 days)
      const [signedUrl] = await file.getSignedUrl({
        action: "read",
        expires: Date.now() + 1000 * 60 * 60 * 24 * 30,
      });

      // ✅ Update Firestore cache
      await cacheDocRef.set({
        storyId: storyId.trim(),
        pageIndex: pageIdxNum,
        lang: normLang,
        voiceId: voiceId.trim(),
        audioUrl: signedUrl,
        storagePath,
        bytes: audioBuffer.length,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      res.json({ audioUrl: signedUrl, cached: false });
    } catch (e: any) {
      const status = typeof e?.status === "number" ? e.status : 500;
      console.error("Error in parentVoiceSpeak:", e);
      res.status(status).json({ error: e?.message || "Server error" });
    }
  }
);
