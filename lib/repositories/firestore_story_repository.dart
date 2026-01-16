import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/story.dart';
import 'story_repository.dart';

class FirestoreStoryRepository implements StoryRepository {
  final FirebaseFirestore _db;

  FirestoreStoryRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Story>> listStories({required StoryQuery query}) async {
    final snap = await _db.collection('stories').get();
    final stories = snap.docs
        .map(_fromDoc)
        .where((s) => s != null)
        .cast<Story>()
        .toList();
    return _applyQuery(stories, query);
  }

  @override
  Future<Story> getStoryById(String id) async {
    final doc = await _db.collection('stories').doc(id).get();
    if (!doc.exists) {
      throw Exception('Story not found: $id');
    }
    final story = _fromDoc(doc);
    if (story == null) {
      throw Exception('Invalid story data: $id');
    }
    return story;
  }

  Story? _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;

    final id = _string(data['id']) ?? doc.id;
    final title = _string(data['title']) ?? '';
    final language = _string(data['language']) ?? 'en';
    final ageBand = _normalizeAge(_string(data['ageBand']) ?? '2-3');
    final cover = _string(data['coverUrl']) ??
        _string(data['cover_url']) ??
        _string(data['coverAsset']) ??
        _string(data['coverPath']) ??
        '';

    final pagesRaw = data['pages'];
    final pages = <StoryPage>[];
    if (pagesRaw is List) {
      for (var i = 0; i < pagesRaw.length; i++) {
        final p = pagesRaw[i];
        if (p is! Map) continue;
        final text = _string(p['text']) ?? '';
        if (text.isEmpty) continue;

        final image = _string(p['imageUrl']) ??
            _string(p['image_url']) ??
            _string(p['image']) ??
            _string(p['imageAsset']) ??
            _string(p['imagePath']);
        final background = _string(p['backgroundUrl']) ??
            _string(p['background_url']) ??
            _string(p['background']) ??
            _string(p['backgroundAsset']) ??
            _string(p['backgroundPath']);
        final hero = _string(p['heroUrl']) ??
            _string(p['hero_url']) ??
            _string(p['hero']) ??
            _string(p['heroAsset']) ??
            _string(p['heroPath']);
        final friend = _string(p['friendUrl']) ??
            _string(p['friend_url']) ??
            _string(p['friend']) ??
            _string(p['friendAsset']) ??
            _string(p['friendPath']);
        final object = _string(p['objectUrl']) ??
            _string(p['object_url']) ??
            _string(p['object']) ??
            _string(p['objectAsset']) ??
            _string(p['objectPath']);
        final audio = _string(p['audioUrl']) ??
            _string(p['audio_url']) ??
            _string(p['audio']) ??
            _string(p['audioPath']);
        final emotion = _string(p['emotionEmoji']) ?? _string(p['emotion']);

        pages.add(
          StoryPage(
            index: i,
            text: text,
            imageAsset: image,
            audioUrl: audio,
            backgroundAsset: background,
            heroAsset: hero,
            friendAsset: friend,
            objectAsset: object,
            emotionEmoji: emotion,
            choices: const [],
          ),
        );
      }
    }

    if (pages.isEmpty) {
      if (kDebugMode) {
        debugPrint('FirestoreStoryRepository: empty pages for $id');
      }
      return null;
    }

    return Story(
      id: id,
      title: title,
      language: language,
      ageBand: ageBand,
      coverAsset: cover,
      pages: pages,
    );
  }

  List<Story> _applyQuery(List<Story> stories, StoryQuery query) {
    final q = query.searchText.trim().toLowerCase();
    final qLang = query.language?.trim().toLowerCase();
    final qAge = query.ageBand?.trim().toLowerCase();
    String norm(String s) => s.trim().toLowerCase();
    String normAge(String s) => norm(s).replaceAll('–', '-').replaceAll('ƒ?"', '-');

    return stories.where((s) {
      final title = norm(s.title);
      final id = norm(s.id);
      final lang = norm(s.language);
      final age = normAge(s.ageBand);

      final matchesSearch =
          q.isEmpty || title.contains(q) || id.contains(q);
      final matchesLang =
          qLang == null || qLang.isEmpty || lang == norm(qLang);
      final matchesAge =
          qAge == null || qAge.isEmpty || age == normAge(qAge);

      return matchesSearch && matchesLang && matchesAge;
    }).toList();
  }

  String? _string(dynamic v) {
    if (v is String) return v.trim();
    return null;
  }

  String _normalizeAge(String raw) {
    return raw.replaceAll('–', '-').replaceAll('ƒ?"', '-');
  }
}
