import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/zen_tree.dart';
import 'package:flutter/foundation.dart';

class ProgressService {
  static const String _todayTreeKey = 'today_zen_tree';
  static const String _legacyForestKey = 'legacy_forest_trees';
  
  static const String _currentStreakKey = 'current_streak';
  static const String _longestStreakKey = 'longest_streak';
  static const String _lastMeditatedKey = 'last_meditated_date';
  static const String _totalMinutesKey = 'total_mindful_minutes';
  static const String _presencePointsKey = 'presence_points';

  /// Initial baseline for presence level.
  static const int presenceBaseline = 100;

  /// Maximum number of recent interactions retained (FIFO).
  static const int presenceFifoCap = 50;

  late SharedPreferences _prefs;

  int get currentStreak => _prefs.getInt(_currentStreakKey) ?? 0;
  int get longestStreak => _prefs.getInt(_longestStreakKey) ?? 0;
  int get totalMindfulMinutes => _prefs.getInt(_totalMinutesKey) ?? 0;

  DateTime? get lastMeditatedDate {
    final str = _prefs.getString(_lastMeditatedKey);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  // ---------------------------------------------------------------------------
  // Presence Level (FIFO queue of +1 / -1 points)
  // ---------------------------------------------------------------------------

  /// Returns the raw list of recent interaction points (+1 or -1).
  List<int> get presencePoints {
    final jsonStr = _prefs.getString(_presencePointsKey);
    if (jsonStr == null) return <int>[];
    try {
      return List<int>.from(jsonDecode(jsonStr) as List);
    } catch (_) {
      return <int>[];
    }
  }

  /// Current Presence Level = baseline (100) + sum(points), clamped to [0, 200].
  int get presenceLevel {
    final sum = presencePoints.fold<int>(0, (a, b) => a + b);
    return (presenceBaseline + sum).clamp(0, 200);
  }

  /// Normalized presence as a 0.0–1.0 ratio (for UI progress bars / scaling).
  double get presenceRatio => presenceLevel / 200.0;

  /// Record a correct interaction (+1 point).
  Future<void> recordHit() async => _addPresencePoint(1);

  /// Record an incorrect / missed interaction (-1 point).
  Future<void> recordMiss() async => _addPresencePoint(-1);

  /// Internal: append a point, enforce FIFO cap, and persist.
  Future<void> _addPresencePoint(int point) async {
    final points = presencePoints;
    points.add(point);
    // Enforce FIFO cap – remove oldest entries first.
    while (points.length > presenceFifoCap) {
      points.removeAt(0);
    }
    await _savePresencePoints(points);
  }

  Future<void> _savePresencePoints(List<int> points) async {
    await _prefs.setString(_presencePointsKey, jsonEncode(points));
  }

  /// Reset the presence queue (e.g. for a new day or testing).
  Future<void> resetPresencePoints() async {
    await _prefs.remove(_presencePointsKey);
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _checkDailyReset();
    _checkStreakReset();
  }

  void _checkStreakReset() {
    final last = lastMeditatedDate;
    if (last == null) return;
    
    final now = DateTime.now();
    final lastDate = DateTime(last.year, last.month, last.day);
    final todayDate = DateTime(now.year, now.month, now.day);
    final diff = todayDate.difference(lastDate).inDays;
    
    if (diff > 1) {
      // Streak broken.
      _prefs.setInt(_currentStreakKey, 0);
    }
  }

  Future<void> completeSession(int durationMinutes) async {
    final now = DateTime.now();
    int newStreak = currentStreak;
    int newLongest = longestStreak;
    int newTotal = totalMindfulMinutes + durationMinutes;
    
    final last = lastMeditatedDate;
    if (last != null) {
      final lastDate = DateTime(last.year, last.month, last.day);
      final todayDate = DateTime(now.year, now.month, now.day);
      final diff = todayDate.difference(lastDate).inDays;
      
      if (diff == 1) {
        newStreak++;
      } else if (diff > 1) {
        newStreak = 1;
      }
      // If diff == 0, we already meditated today (or last date was today), so streak is already +1 or started for today.
      // Wait, if diff == 0 but currentStreak == 0 (e.g. manually cleared or fresh), we should ensure it is at least 1.
      if (diff == 0 && newStreak == 0) {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }
    
    if (newStreak > newLongest) {
      newLongest = newStreak;
    }

    await _prefs.setInt(_currentStreakKey, newStreak);
    await _prefs.setInt(_longestStreakKey, newLongest);
    await _prefs.setString(_lastMeditatedKey, now.toIso8601String());
    await _prefs.setInt(_totalMinutesKey, newTotal);
    
    _syncToSupabase(newStreak, newLongest, newTotal, now);
  }

  Future<void> _syncToSupabase(int streak, int longest, int minutes, DateTime lastDate) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      await Supabase.instance.client.from('user_profiles').upsert({
        'id': user.id,
        'current_streak': streak,
        'longest_streak': longest,
        'total_mindful_minutes': minutes,
        'last_meditated_date': lastDate.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Streak sync failed: $e');
    }
  }

  void _checkDailyReset() {
    final today = getTodayTree();
    final now = DateTime.now();

    // If there is no tree, or the tree is from a previous day
    if (today == null || now.difference(today.date).inDays > 0 || now.day != today.date.day) {
      if (today != null && today.leafCount > 0) {
        _moveToLegacyForest(today);
      }
      
      final newTree = ZenTreeData(date: now, leafCount: 0);
      _saveTodayTree(newTree);
    }
  }

  ZenTreeData? getTodayTree() {
    final jsonStr = _prefs.getString(_todayTreeKey);
    if (jsonStr != null) {
      try {
        return ZenTreeData.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> incrementLeaf() async {
    final today = getTodayTree();
    if (today != null) {
      today.leafCount += 1;
      await _saveTodayTree(today);
    }
    // A correct tap is also a positive presence interaction.
    await recordHit();
  }

  Future<void> _saveTodayTree(ZenTreeData tree) async {
    await _prefs.setString(_todayTreeKey, jsonEncode(tree.toJson()));
  }

  void _moveToLegacyForest(ZenTreeData tree) {
    List<String> legacyJsonList = _prefs.getStringList(_legacyForestKey) ?? [];
    legacyJsonList.add(jsonEncode(tree.toJson()));
    _prefs.setStringList(_legacyForestKey, legacyJsonList);
  }

  List<ZenTreeData> getLegacyForest() {
    final legacyJsonList = _prefs.getStringList(_legacyForestKey) ?? [];
    return legacyJsonList.map((str) {
      return ZenTreeData.fromJson(jsonDecode(str));
    }).toList();
  }
}
