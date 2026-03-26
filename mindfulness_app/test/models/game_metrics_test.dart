import 'package:flutter_test/flutter_test.dart';
import 'package:mindaware/models/game_metrics.dart';

void main() {
  group('GameMetrics – Deep Focus Logic', () {
    late GameMetrics metrics;

    setUp(() {
      metrics = GameMetrics();
    });

    test('averageReactionTime only includes correct tap durations', () {
      metrics.recordTap(isCorrect: true, reactionTime: const Duration(seconds: 1));
      metrics.recordTap(isCorrect: false, reactionTime: const Duration(seconds: 5));

      // Only the correct tap's reactionTime should be recorded
      expect(metrics.reactionTimes.length, 1);
      expect(metrics.averageReactionTime, const Duration(seconds: 1));
    });

    test('averageReactionTime is zero when no correct taps', () {
      metrics.recordTap(isCorrect: false, reactionTime: const Duration(seconds: 5));
      metrics.recordTap(isCorrect: false, reactionTime: const Duration(seconds: 5));

      expect(metrics.reactionTimes, isEmpty);
      expect(metrics.averageReactionTime, Duration.zero);
    });

    test('averageReactionTime averages only over correct taps', () {
      metrics.recordTap(isCorrect: true, reactionTime: const Duration(seconds: 2));
      metrics.recordTap(isCorrect: true, reactionTime: const Duration(seconds: 4));
      metrics.recordTap(isCorrect: false, reactionTime: const Duration(seconds: 5)); // should be ignored

      expect(metrics.reactionTimes.length, 2);
      expect(metrics.averageReactionTime, const Duration(seconds: 3)); // (2+4)/2
    });

    test('correctTaps and wrongTaps are tracked independently', () {
      metrics.recordTap(isCorrect: true, reactionTime: const Duration(seconds: 1));
      metrics.recordTap(isCorrect: false, reactionTime: const Duration(seconds: 5));
      metrics.recordTap(isCorrect: true, reactionTime: const Duration(seconds: 2));

      expect(metrics.correctTaps, 2);
      expect(metrics.wrongTaps, 1);
      expect(metrics.totalTaps, 3);
    });

    test('streak breaks on miss and does not affect reactionTimes', () {
      metrics.recordTap(isCorrect: true, reactionTime: const Duration(seconds: 1));
      metrics.recordTap(isCorrect: true, reactionTime: const Duration(seconds: 1));
      expect(metrics.currentStreak, 2);

      metrics.recordTap(isCorrect: false, reactionTime: const Duration(seconds: 5));
      expect(metrics.currentStreak, 0);
      expect(metrics.reactionTimes.length, 2); // Still only 2 from the correct taps
    });

    test('treeGrowthLevel increases every 5 correct taps in a row', () {
      for (int i = 0; i < 5; i++) {
        metrics.recordTap(isCorrect: true, reactionTime: const Duration(seconds: 1));
      }
      expect(metrics.treeGrowthLevel, 1);
    });
  });
}
