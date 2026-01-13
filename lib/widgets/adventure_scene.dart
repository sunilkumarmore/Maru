import 'package:flutter/material.dart';
import 'package:suzyapp/utils/asset_path.dart';
import '../design_system/app_radius.dart';
import '../design_system/app_colors.dart';

class AdventureScene extends StatelessWidget {
  final String? backgroundAsset; // e.g. assets/scenes/bg_park.png
  final String? heroAsset; // e.g. assets/characters/bear.png
  final String? friendAsset; // optional
  final String? objectAsset; // optional
  final String? emotionEmoji; // optional "😊"

  const AdventureScene({
    super.key,
    this.backgroundAsset,
    this.heroAsset,
    this.friendAsset,
    this.objectAsset,
    this.emotionEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final bg = AssetPath.normalize(backgroundAsset);
    final hero = AssetPath.normalize(heroAsset);
    final friend = AssetPath.normalize(friendAsset);
    final obj = AssetPath.normalize(objectAsset);
    return AspectRatio(
      // keeps scene proportions stable across devices
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Container(
          color: AppColors.surface,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final h = c.maxHeight;

              // scale elements relative to container size
              final heroSize = w * 0.45;
              final friendSize = w * 0.30;
              final objSize = w * 0.18;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // 1) Background
                  if (bg.isNotEmpty)
                    Image.asset(
                      bg,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    )
                  else
                    _softGradientFallback(),

                  // slight darkening to improve text/emoji contrast (subtle)
                  Container(color: Colors.black.withOpacity(0.03)),

                  // 2) Hero (center-bottom)
                  if (hero.isNotEmpty)
                    Positioned(
                      left: (w - heroSize) / 2,
                      top: h - heroSize * 0.95,
                      width: heroSize,
                      height: heroSize,
                      child: _assetPng(hero),
                    ),

                  // 3) Friend (right side)
                  if (friend.isNotEmpty)
                    Positioned(
                      right: w * 0.06,
                      top: h * 0.50,
                      width: friendSize,
                      height: friendSize,
                      child: _assetPng(friend),
                    ),

                  // 4) Object (bottom-left corner)
                  if (obj.isNotEmpty)
                    Positioned(
                      left: w * 0.06,
                      bottom: h * 0.06,
                      width: objSize,
                      height: objSize,
                      child: _assetPng(obj),
                    ),
                  // 5) Emotion bubble (top-left)
                  if (emotionEmoji != null && emotionEmoji!.isNotEmpty)
                    Positioned(
                      left: w * 0.06,
                      top: h * 0.06,
                      child: _EmotionBubble(emoji: emotionEmoji!),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

Widget _assetPng(String path) {
  return Image.asset(
    path,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    errorBuilder: (_, e, __) {
      debugPrint('AdventureScene asset load error: $path -> $e');
      return const SizedBox.shrink();
    },
  );
}

  Widget _softGradientFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEFE6D8), Color(0xFFF7EFE3)],
        ),
      ),
    );
  }
}

class _EmotionBubble extends StatelessWidget {
  final String emoji;
  const _EmotionBubble({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 26, height: 1)),
    );
  }
}
