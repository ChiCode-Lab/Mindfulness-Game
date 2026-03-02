import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulness_app/models/game_settings.dart';

void main() {
  group('GameSettings – Grid Configuration', () {
    test('Default 4x4 grid has 16 cells and is square', () {
      final settings = GameSettings();
      expect(settings.totalCells, 16);
      expect(settings.isSquare, true);
      expect(settings.aspectRatio, 1.0);
    });

    test('4x3 grid has 12 cells and is non-square', () {
      final settings = GameSettings(gridColumns: 4, gridRows: 3);
      expect(settings.totalCells, 12);
      expect(settings.isSquare, false);
      expect(settings.aspectRatio, closeTo(4 / 3, 0.01));
    });

    test('2x2 grid has 4 cells', () {
      final settings = GameSettings(gridColumns: 2, gridRows: 2);
      expect(settings.totalCells, 4);
      expect(settings.isSquare, true);
    });

    test('3x3 grid has 9 cells', () {
      final settings = GameSettings(gridColumns: 3, gridRows: 3);
      expect(settings.totalCells, 9);
    });

    test('Session duration is configurable and affects Opal cost', () {
      final short = GameSettings(gridColumns: 3, gridRows: 3, sessionDuration: const Duration(minutes: 3));
      final long  = GameSettings(gridColumns: 3, gridRows: 3, sessionDuration: const Duration(minutes: 15));
      expect(short.calculateOpalCost(), lessThan(long.calculateOpalCost()));
      expect(short.sessionDuration.inMinutes, 3);
    });

    test('gridSize backward-compat getter returns gridColumns', () {
      final settings = GameSettings(gridColumns: 4, gridRows: 3);
      expect(settings.gridSize, 4);
    });

    test('Opal cost scales with grid size', () {
      final small = GameSettings(gridColumns: 2, gridRows: 2);
      final large = GameSettings(gridColumns: 4, gridRows: 4);
      expect(small.calculateOpalCost(), lessThan(large.calculateOpalCost()));
    });

    test('Multiplayer adds 30% surcharge', () {
      final solo = GameSettings(gridColumns: 3, gridRows: 3);
      final coop = GameSettings(gridColumns: 3, gridRows: 3, isMultiplayer: true);
      expect(coop.calculateOpalCost(), greaterThan(solo.calculateOpalCost()));
    });
  });
}
