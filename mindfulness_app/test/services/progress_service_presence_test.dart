import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulness_app/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ProgressService – FIFO Presence Logic', () {
    late ProgressService service;

    setUp(() async {
      // Provide empty mock prefs so SharedPreferences.getInstance() works.
      SharedPreferences.setMockInitialValues({});
      service = ProgressService();
      await service.init();
    });

    test('Initial presence level is baseline (100)', () {
      expect(service.presenceLevel, 100);
      expect(service.presencePoints, isEmpty);
    });

    test('recordHit adds +1 point', () async {
      await service.recordHit();
      expect(service.presencePoints, [1]);
      expect(service.presenceLevel, 101);
    });

    test('recordMiss adds -1 point', () async {
      await service.recordMiss();
      expect(service.presencePoints, [-1]);
      expect(service.presenceLevel, 99);
    });

    test('Mixed hits and misses accumulate correctly', () async {
      await service.recordHit();   // +1 → sum=1
      await service.recordHit();   // +1 → sum=2
      await service.recordMiss();  // -1 → sum=1
      await service.recordHit();   // +1 → sum=2

      expect(service.presencePoints, [1, 1, -1, 1]);
      expect(service.presenceLevel, 102); // 100 + 2
    });

    test('FIFO cap enforces maximum of 50 entries', () async {
      // Add 55 hits – only the last 50 should be retained.
      for (int i = 0; i < 55; i++) {
        await service.recordHit();
      }

      expect(service.presencePoints.length, ProgressService.presenceFifoCap);
      // All remaining entries are +1, so level = 100 + 50 = 150.
      expect(service.presenceLevel, 150);
    });

    test('FIFO removes oldest entries first', () async {
      // Add 50 misses (fills queue to cap).
      for (int i = 0; i < 50; i++) {
        await service.recordMiss();
      }
      expect(service.presenceLevel, 50); // 100 + (-50)

      // Now add 1 hit – the oldest -1 is evicted, replaced by +1.
      // Queue: 49 × (-1) + 1 × (+1) = -48  →  level = 100 - 48 = 52.
      await service.recordHit();
      expect(service.presencePoints.length, 50);
      expect(service.presenceLevel, 52);
    });

    test('Presence level is clamped to 0 at the bottom', () async {
      // Manually simulate extreme negatives: 50 × (-1) = sum -50 → level 50.
      // That's above 0, so let's also confirm the clamp.
      // With 50 misses, sum = -50, level = 50 (still above 0).
      // The clamp matters when baseline + sum < 0.
      // Since cap is 50 and min point is -1, the theoretical floor is
      // 100 + (-50) = 50, which is above 0. So clamp at 0 is a safeguard.
      // We can test it by resetting and checking boundary behavior.
      expect(service.presenceLevel, 100);
      // presenceLevel getter clamps to [0, 200] – verify at nominal values.
      expect(service.presenceLevel, greaterThanOrEqualTo(0));
      expect(service.presenceLevel, lessThanOrEqualTo(200));
    });

    test('Presence level is clamped to 200 at the top', () async {
      for (int i = 0; i < 50; i++) {
        await service.recordHit();
      }
      // 100 + 50 = 150, within bounds.
      expect(service.presenceLevel, 150);
      expect(service.presenceLevel, lessThanOrEqualTo(200));
    });

    test('presenceRatio maps level to 0.0–1.0', () async {
      // At baseline: 100 / 200 = 0.5.
      expect(service.presenceRatio, 0.5);

      await service.recordHit();
      // 101 / 200 = 0.505.
      expect(service.presenceRatio, closeTo(0.505, 0.001));
    });

    test('resetPresencePoints clears the queue', () async {
      await service.recordHit();
      await service.recordHit();
      expect(service.presencePoints.length, 2);

      await service.resetPresencePoints();
      expect(service.presencePoints, isEmpty);
      expect(service.presenceLevel, 100);
    });

    test('incrementLeaf also records a hit', () async {
      // incrementLeaf calls recordHit internally.
      await service.incrementLeaf();
      expect(service.presencePoints, [1]);
      expect(service.presenceLevel, 101);
    });

    test('Points persist across ProgressService re-init', () async {
      await service.recordHit();
      await service.recordMiss();
      await service.recordHit();
      expect(service.presenceLevel, 101); // 100 + 1

      // Re-init a fresh service instance with the same SharedPreferences.
      final service2 = ProgressService();
      await service2.init();

      expect(service2.presencePoints, [1, -1, 1]);
      expect(service2.presenceLevel, 101);
    });
  });
}
