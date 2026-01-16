import 'package:flutter/foundation.dart';

import '../models/story.dart';
import 'story_repository.dart';

class CompositeStoryRepository implements StoryRepository {
  final StoryRepository primary;
  final StoryRepository fallback;

  CompositeStoryRepository({
    required this.primary,
    required this.fallback,
  });

  @override
  Future<List<Story>> listStories({required StoryQuery query}) async {
    List<Story> remote = [];
    try {
      remote = await primary.listStories(query: query);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CompositeStoryRepository primary list failed: $e');
      }
    }

    List<Story> local = [];
    try {
      local = await fallback.listStories(query: query);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CompositeStoryRepository fallback list failed: $e');
      }
    }

    if (remote.isEmpty) return local;
    if (local.isEmpty) return remote;

    final merged = <String, Story>{};
    for (final s in local) {
      merged[s.id] = s;
    }
    for (final s in remote) {
      merged[s.id] = s; // remote overrides local on id clash
    }
    return merged.values.toList();
  }

  @override
  Future<Story> getStoryById(String id) async {
    try {
      return await primary.getStoryById(id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CompositeStoryRepository primary get failed: $e');
      }
      return fallback.getStoryById(id);
    }
  }
}
