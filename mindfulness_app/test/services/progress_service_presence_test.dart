import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulness_app/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ProgressService – FIFO Presence Logic (Dual Metrics)', () {
    late ProgressService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      // Explicitly clear any existing singleton state if possible
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      service = ProgressService();
      await service.init();
    });

    test('Initial presence levels are baseline (100)', () {
      expect(service.sessionPresenceLevel, 100);
      expect(service.dailyPresenceLevel, 100);
    });

    test('recordHit keeps levels at 100 (clamped)', () async {
      await service.recordHit();
      // Sum = 1. level = 100 + 1 = 101, clamped to 100.
      expect(service.sessionPresenceLevel, 100);
      expect(service.dailyPresenceLevel, 100);
    });

    test('recordMiss reduces levels to 99', () async {
      await service.recordMiss();
      // Total hits/misses = -1. Baseline = 100.
      expect(service.sessionPresenceLevel, 99, reason: 'Session Level should be 99');
      expect(service.dailyPresenceLevel, 99, reason: 'Daily Level should be 99');
    });

    test('Session reset (startSession) clears Metric 1 but keeps Metric 2', () async {
      await service.recordMiss(); // Daily=99, Session=99
      expect(service.sessionPresenceLevel, 99);
      expect(service.dailyPresenceLevel, 99);

      service.startSession(); // Reset Session
      expect(service.sessionPresenceLevel, 100);
      expect(service.dailyPresenceLevel, 99); // Daily persists
    });

    test('Daily aggregated hits/misses across sessions', () async {
      service.startSession();
      await service.recordMiss(); // Session=99, Daily=99
      await service.recordMiss(); // Session=98, Daily=98

      service.startSession(); // Next session
      await service.recordMiss(); // Session=99, Daily=97
      
      expect(service.sessionPresenceLevel, 99);
      expect(service.dailyPresenceLevel, 97);
    });

    test('FIFO cap enforces maximum of 100 entries', () async {
      // Metric 1 & 2 start at 100. We add 110 misses.
      // Sum = -110. Baseline (100) + Sum (-100 after FIFO cap) = 0.
      for (int i = 0; i < 110; i++) {
        await service.recordMiss();
      }

      expect(service.sessionPresenceLevel, 0);
      expect(service.dailyPresenceLevel, 0);
    });

    test('dailyPresenceRatio maps level to 0.0–1.0', () async {
      // At baseline 100: 100 / 100 = 1.0.
      expect(service.dailyPresenceRatio, 1.0);

      await service.recordMiss();
      // 99 / 100 = 0.99.
      expect(service.dailyPresenceRatio, 0.99);
    });

    test('resetPresencePoints clears Daily Metric', () async {
      await service.recordMiss();
      expect(service.dailyPresenceLevel, 99);

      await service.resetPresencePoints();
      expect(service.dailyPresenceLevel, 100);
    });

    test('incrementLeaf also records a hit (Daily Metric)', () async {
      // Since it starts at 100, hit keeps it at 100.
      // Let's drop it first.
      await service.recordMiss();
      expect(service.dailyPresenceLevel, 99);
      
      await service.incrementLeaf();
      expect(service.dailyPresenceLevel, 100);
    });

    test('Daily metrics persist across ProgressService re-init', () async {
      await service.recordMiss();
      expect(service.dailyPresenceLevel, 99);

      final service2 = ProgressService();
      await service2.init();

      expect(service2.dailyPresenceLevel, 99);
    });
  });
}
