import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/reading_progress.dart';
import '../models/story_progress.dart';
import 'progress_repository.dart';

class LocalProgressRepository extends  ProgressRepository {
  static const _kReadingProgress = 'progress.reading.last'; // last opened story/page
  static const _kStoryProgressMap = 'progress.story.map'; // storyId -> StoryProgress map

  // -------- ReadingProgress (global "last") --------

  @override
  Future<ReadingProgress?> getReadingProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kReadingProgress);
    if (raw == null || raw.isEmpty) return null;

    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return _readingFromMap(m);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveReadingProgress(ReadingProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final m = _readingToMap(progress);
    await prefs.setString(_kReadingProgress, jsonEncode(m));
  }

  @override
  Future<void> clearReadingProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kReadingProgress);
  }

  // -------- StoryProgress (per story) --------

  @override
  Future<StoryProgress?> getStoryProgress(String storyId) async {
    final map = await _loadStoryProgressMap();
    final m = map[storyId];
    if (m == null) return null;
    try {
      return _storyFromMap(m);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<StoryProgress>> getAllStoryProgress() async {
    final map = await _loadStoryProgressMap();
    final out = <StoryProgress>[];
    for (final entry in map.entries) {
      try {
        out.add(_storyFromMap(entry.value));
      } catch (_) {
        // ignore malformed entries
      }
    }

    // Sort by most recent activity (nice for Parent Summary / Library badges)
    out.sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
    return out;
  }

  @override
  Future<void> saveStoryProgress(StoryProgress progress) async {
    final map = await _loadStoryProgressMap();
    map[progress.storyId] = _storyToMap(progress);
    await _saveStoryProgressMap(map);
  }

  // -------- Internal storage helpers --------

  Future<Map<String, Map<String, dynamic>>> _loadStoryProgressMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStoryProgressMap);
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final out = <String, Map<String, dynamic>>{};
      for (final e in decoded.entries) {
        final v = e.value;
        if (v is Map<String, dynamic>) {
          out[e.key] = v;
        } else if (v is Map) {
          out[e.key] = v.map((k, val) => MapEntry(k.toString(), val));
        }
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveStoryProgressMap(Map<String, Map<String, dynamic>> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStoryProgressMap, jsonEncode(map));
  }

  // -------- Model mappers (avoid needing toJson/fromJson) --------

  Map<String, dynamic> _readingToMap(ReadingProgress p) => {
        'storyId': p.storyId,
        'pageIndex': p.pageIndex,
        'updatedAt': p.updatedAt.toIso8601String(),
      };

  ReadingProgress _readingFromMap(Map<String, dynamic> m) => ReadingProgress(
        storyId: (m['storyId'] as String?) ?? '',
        pageIndex: (m['pageIndex'] as num?)?.toInt() ?? 0,
        updatedAt: DateTime.tryParse((m['updatedAt'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  Map<String, dynamic> _storyToMap(StoryProgress p) => {
        'storyId': p.storyId,
        'lastPageIndex': p.lastPageIndex,
        'completed': p.completed,
        'lastOpenedAt': p.lastOpenedAt.toIso8601String(),
      };

  StoryProgress _storyFromMap(Map<String, dynamic> m) => StoryProgress(
        storyId: (m['storyId'] as String?) ?? '',
        lastPageIndex: (m['lastPageIndex'] as num?)?.toInt() ?? 0,
        completed: (m['completed'] as bool?) ?? false,
        lastOpenedAt: DateTime.tryParse((m['lastOpenedAt'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  // ✅ Do NOT implement getLastProgress/saveProgress/clearProgress here.
  // Your abstract ProgressRepository already provides default implementations.
}
