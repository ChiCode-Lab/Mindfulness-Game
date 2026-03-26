import 'package:flutter_test/flutter_test.dart';
import 'package:mindaware/models/game_settings.dart';

void main() {
  group('Pricing Calculator', () {
    test('Calculates simple solo cost correctly', () {
      final baseSettings = GameSettings(
        gridColumns: 3,
        gridRows: 3,
        sessionDuration: const Duration(minutes: 5),
        soundscape: Soundscape.none,
        isMultiplayer: false,
      );
      // Formula: (cols * rows * 0.5) + (minutes * 5.0)
      // (3 * 3 * 0.5) + (5 * 5) = 4.5 + 25 = 29.5 → 30 Opals
      expect(baseSettings.calculateOpalCost(isPremiumAudio: false), 30);
    });

    test('Higher grid and higher time cost significantly more', () {
      final highTierSettings = GameSettings(
        gridColumns: 4,
        gridRows: 4,
        sessionDuration: const Duration(minutes: 10),
        soundscape: Soundscape.none,
        isMultiplayer: false,
      );
      // (4 * 4 * 0.5) + (10 * 5) = 8 + 50 = 58 Opals
      expect(highTierSettings.calculateOpalCost(isPremiumAudio: false), 58);
    });

    test('Cooperative multiplier is correctly applied', () {
      final baseSettings = GameSettings(
        gridColumns: 3,
        gridRows: 3,
        sessionDuration: const Duration(minutes: 5),
        soundscape: Soundscape.none,
        isMultiplayer: true,
      );
      // Base is 29.5. Cooperative is 1.3x → 38.35 → 38 Opals
      expect(baseSettings.calculateOpalCost(isPremiumAudio: false), 38);
    });

    test('Premium audio adds flat surcharge', () {
      final baseSettings = GameSettings(
        gridColumns: 3,
        gridRows: 3,
        sessionDuration: const Duration(minutes: 5),
        soundscape: Soundscape.oceanWaves,
        isMultiplayer: false,
      );
      // Base is 29.5. Premium Audio adds flat 20 Opals → 49.5 → 50 Opals
      expect(baseSettings.calculateOpalCost(isPremiumAudio: true), 50);
    });

    test('4x3 grid costs less than 4x4 same duration', () {
      final rect  = GameSettings(gridColumns: 4, gridRows: 3, sessionDuration: const Duration(minutes: 5));
      final square = GameSettings(gridColumns: 4, gridRows: 4, sessionDuration: const Duration(minutes: 5));
      expect(rect.calculateOpalCost(), lessThan(square.calculateOpalCost()));
    });
  });
}
