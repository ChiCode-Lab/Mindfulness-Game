import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/zen_tree.dart';
import 'package:flutter/foundation.dart';
import 'deep_link_service.dart';

class ProgressService {
  static const String _todayTreeKey = 'today_zen_tree';
  static const String _legacyForestKey = 'legacy_forest_trees';
  
  static const String _currentStreakKey = 'current_streak';
  static const String _longestStreakKey = 'longest_streak';
  static const String _lastMeditatedKey = 'last_meditated_date';
  static const String _totalMinutesKey = 'total_mindful_minutes';
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

  /// Metric 3: Presence-based streak modifier.
  double get presenceStreakMultiplier {
    return (dailyPresenceLevel / 100.0).clamp(0.5, 1.0);
  }

  /// Record a +1 (Success) point in the presence FIFO.
  Future<void> recordHit() async {
    await _addPresencePoint(1);
    
    final today = getTodayTree();
    if (today != null) {
      today.presenceLevel = dailyPresenceLevel;
      await _saveTodayTree(today);
    }
  }

  /// Record a -1 (Failure) point in the presence FIFO.
  Future<void> recordMiss() async {
    await _addPresencePoint(-1);
    
    final today = getTodayTree();
    if (today != null) {
      today.presenceLevel = dailyPresenceLevel;
      await _saveTodayTree(today);
    }
  }

  Future<void> _addPresencePoint(int point) async {
    _sessionPoints.add(point);
    while (_sessionPoints.length > presenceFifoCap) {
      _sessionPoints.removeAt(0);
    }
    
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
    await _checkDailyReset();
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
    
    _syncToSupabase(newStreak, newLongest, newTotal, now, durationMinutes);
  }

  Future<void> _syncToSupabase(int streak, int longest, int minutes, DateTime lastDate, int sessionDuration) async {
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

      final countRes = await Supabase.instance.client
          .from('progress')
          .select('id')
          .eq('user_id', user.id);
      
      final isFirstOverall = countRes.isEmpty;

      await Supabase.instance.client.from('progress').insert({
        'user_id': user.id,
        'session_type': 'solo',
        'duration_seconds': sessionDuration * 60,
      });

      if (isFirstOverall) {
        debugPrint('First session recorded — Triggering referral logic in SQL');
      }

    } catch (e) {
      debugPrint('Streak sync failed: $e');
    }
  }

  Future<void> _checkDailyReset() async {
    final today = getTodayTree();
    final now = DateTime.now();

    if (today == null || now.difference(today.date).inDays > 0 || now.day != today.date.day) {
      if (today != null && today.leafCount > 0) {
        await _moveToLegacyForest(today);
      }
      await resetPresencePoints();

      final newTree = ZenTreeData(date: now, leafCount: 0, presenceLevel: presenceBaseline);
      await _saveTodayTree(newTree);
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
    await recordHit();
  }

  Future<void> _saveTodayTree(ZenTreeData tree) async {
    await _prefs.setString(_todayTreeKey, jsonEncode(tree.toJson()));
  }

  Future<void> _moveToLegacyForest(ZenTreeData tree) async {
    List<String> legacyJsonList = _prefs.getStringList(_legacyForestKey) ?? [];
    legacyJsonList.add(jsonEncode(tree.toJson()));
    await _prefs.setStringList(_legacyForestKey, legacyJsonList);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('legacy_forest').insert({
          'user_id': user.id,
          'tree_data': tree.toJson(),
          'created_at': tree.date.toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Legacy forest sync failed: $e');
    }
  }

  Future<List<ZenTreeData>> fetchPublicForest(String username) async {
    try {
      final profileRes = await Supabase.instance.client
          .from('user_profiles')
          .select('id')
          .eq('username', username)
          .single();
      
      final userId = profileRes['id'];

      final List<dynamic> res = await Supabase.instance.client
          .from('legacy_forest')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return res.map((item) => ZenTreeData.fromJson(item['tree_data'])).toList();
    } catch (e) {
      debugPrint('Failed to fetch public forest: $e');
      return [];
    }
  }

  List<ZenTreeData> getLegacyForest() {
    final legacyJsonList = _prefs.getStringList(_legacyForestKey) ?? [];
    return legacyJsonList.map((str) {
      return ZenTreeData.fromJson(jsonDecode(str));
    }).toList();
  }
}
