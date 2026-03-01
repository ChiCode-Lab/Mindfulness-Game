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
  static const String _sessionPointsKey = 'session_presence_points_ephemeral'; // In-memory typically, but let's be safe
  static const String _presencePointsKey = 'presence_points_daily';

  /// Initial baseline for presence level (Metric 1 & 2 start at 100/100).
  static const int presenceBaseline = 100;

  /// Maximum depth of the FIFO queue. A 100-point window allows for smooth 0-100% scaling.
  static const int presenceFifoCap = 100;

  /// Metric 1: Ephemeral session-level presence points.
  List<int> _sessionPoints = [];

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

  /// Prepares the service for a new discrete session.
  /// Metric 1 (Session Level) is reset to 100.
  void startSession() {
    _sessionPoints = [];
  }

  /// Returns the persistent daily presence points (+1 or -1).
  List<int> get _dailyPresencePoints {
    final jsonStr = _prefs.getString(_presencePointsKey);
    if (jsonStr == null) return <int>[];
    try {
      return List<int>.from(jsonDecode(jsonStr) as List);
    } catch (_) {
      return <int>[];
    }
  }

  /// Metric 1 (Session Level): Ephemeral FIFO, starts at 100, clamped at 0.
  int get sessionPresenceLevel {
    int sum = 0;
    for (final p in _sessionPoints) {
      sum += p;
    }
    // Baseline 100. If sum is -1, result is 99.
    // Clamping at 100 means hits at the start don't increase it, 
    // but the first miss will immediately drop it.
    return (presenceBaseline + sum).clamp(0, 100);
  }

  /// Metric 2 (Daily Level): Persistent FIFO, starts at 100 at 00:00, aggregates all sessions.
  int get dailyPresenceLevel {
    int sum = 0;
    for (final p in _dailyPresencePoints) {
      sum += p;
    }
    return (presenceBaseline + sum).clamp(0, 100);
  }

  /// Normalized daily presence as a 0.0–1.0 ratio.
  double get dailyPresenceRatio => dailyPresenceLevel / 100.0;

  /// Record a correct interaction (+1 point) for both Session and Daily levels.
  Future<void> recordHit() async {
    await _addPresencePoint(1);
    
    // Sync Metric 2 (Daily) to today's tree snapshot
    final today = getTodayTree();
    if (today != null) {
      today.presenceLevel = dailyPresenceLevel;
      await _saveTodayTree(today);
    }
  }

  /// Record an incorrect / missed interaction (-1 point) for both Session and Daily levels.
  Future<void> recordMiss() async {
    await _addPresencePoint(-1);
    
    // Sync Metric 2 (Daily) to today's tree snapshot
    final today = getTodayTree();
    if (today != null) {
      today.presenceLevel = dailyPresenceLevel;
      await _saveTodayTree(today);
    }
  }

  /// Internal: append a point to BOTH sub-queues (Session and Daily).
  Future<void> _addPresencePoint(int point) async {
    // 1. Update Ephemeral Session Points
    _sessionPoints.add(point);
    while (_sessionPoints.length > presenceFifoCap) {
      _sessionPoints.removeAt(0);
    }

    // 2. Update Persistent Daily Points
    final jsonStr = _prefs.getString(_presencePointsKey);
    List<int> currentDaily = [];
    if (jsonStr != null) {
      try {
        currentDaily = List<int>.from(jsonDecode(jsonStr) as List);
      } catch (_) {}
    }
    
    currentDaily.add(point);
    while (currentDaily.length > presenceFifoCap) {
      currentDaily.removeAt(0);
    }
    await _prefs.setString(_presencePointsKey, jsonEncode(currentDaily));
    
    debugPrint('Added presence point: $point. Session Level: $sessionPresenceLevel, Daily Level: $dailyPresenceLevel');
  }

  /// Reset the daily presence queue (happens at 00:00).
  Future<void> resetPresencePoints() async {
    await _prefs.remove(_presencePointsKey);
    _sessionPoints = [];
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
      
      // Reset presence scores for the new day
      resetPresencePoints();
      
      final newTree = ZenTreeData(date: now, leafCount: 0, presenceLevel: presenceBaseline);
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
    // Updating leafCount THEN recording hit ensures the tree's final state for the session
    // takes into account the last action's presence impact via recordHit's auto-sync.
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
