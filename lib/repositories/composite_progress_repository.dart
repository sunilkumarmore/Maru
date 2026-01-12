import '../models/reading_progress.dart';
import '../models/story_progress.dart';
import 'progress_repository.dart';

/// Offline-first composite:
/// - Reads come from `local`
/// - Writes go to `local` and best-effort to `cloud`
/// - Clear clears local and best-effort clears cloud
class CompositeProgressRepository extends  ProgressRepository {
  final ProgressRepository local;
  final ProgressRepository cloud;

  CompositeProgressRepository({
    required this.local,
    required this.cloud,
  });

  // ===== NEW (clear naming) =====

  @override
  Future<ReadingProgress?> getReadingProgress() async {
    return local.getReadingProgress();
  }

  @override
  Future<void> saveReadingProgress(ReadingProgress progress) async {
    await local.saveReadingProgress(progress);
    try {
      await cloud.saveReadingProgress(progress);
    } catch (_) {
      // offline / permission / network: ignore
    }
  }

  @override
  Future<void> clearReadingProgress() async {
    await local.clearReadingProgress();
    try {
      await cloud.clearReadingProgress();
    } catch (_) {}
  }

  @override
  Future<StoryProgress?> getStoryProgress(String storyId) async {
    return local.getStoryProgress(storyId);
  }

  @override
  Future<List<StoryProgress>> getAllStoryProgress() async {
    return local.getAllStoryProgress();
  }

  @override
  Future<void> saveStoryProgress(StoryProgress progress) async {
    await local.saveStoryProgress(progress);
    try {
      await cloud.saveStoryProgress(progress);
    } catch (_) {}
  }

  // ✅ Do NOT implement getLastProgress/saveProgress/clearProgress here.
  // Your abstract ProgressRepository already provides default implementations.
}
