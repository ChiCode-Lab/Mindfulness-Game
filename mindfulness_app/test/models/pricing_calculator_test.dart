import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulness_app/models/game_settings.dart';

void main() {
  group('Pricing Calculator', () {
    test('Calculates simple solo cost correctly', () {
      final baseSettings = GameSettings(
        gridSize: 3, 
        sessionDuration: const Duration(minutes: 5), 
        soundscape: Soundscape.none,
        isMultiplayer: false,
      );
      // Expected formula: (gridSize * 2) + (sessionDuration.inMinutes * 5)
      // (3 * 2) + (5 * 5) = 6 + 25 = 31 Opals
      expect(baseSettings.calculateOpalCost(isPremiumAudio: false), 31);
    });

    test('Higher grid and higher time cost significantly more', () {
      final highTierSettings = GameSettings(
        gridSize: 5,
        sessionDuration: const Duration(minutes: 10),
        soundscape: Soundscape.none,
        isMultiplayer: false,
      );
      // (5 * 2) + (10 * 5) = 10 + 50 = 60 Opals
      expect(highTierSettings.calculateOpalCost(isPremiumAudio: false), 60);
    });

    test('Cooperative multiplier is correctly applied', () {
      final baseSettings = GameSettings(
        gridSize: 3,
        sessionDuration: const Duration(minutes: 5),
        soundscape: Soundscape.none,
        isMultiplayer: true,
      );
      // Base is 31. Cooperative is 1.3x
      // 31 * 1.3 = 40.3 -> rounded -> 40 Opals
      expect(baseSettings.calculateOpalCost(isPremiumAudio: false), 40);
    });

    test('Premium audio adds flat surcharge', () {
      final baseSettings = GameSettings(
        gridSize: 3,
        sessionDuration: const Duration(minutes: 5),
        soundscape: Soundscape.oceanWaves,
        isMultiplayer: false,
      );
      // Base is 31. Premium Audio adds flat 20 Opals.
      expect(baseSettings.calculateOpalCost(isPremiumAudio: true), 51);
    });
  });
}
