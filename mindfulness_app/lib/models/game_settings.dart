enum Soundscape {
  rainThunder,
  oceanWaves,
  campfire,
  forestUnderwater,
  none,
}

class GameSettings {
  int gridColumns; // columns (X axis)
  int gridRows;    // rows (Y axis)
  Duration sessionDuration;
  Soundscape soundscape;
  bool isMultiplayer;

  GameSettings({
    this.gridColumns = 4,
    this.gridRows = 4,
    this.sessionDuration = const Duration(minutes: 5),
    this.soundscape = Soundscape.none,
    this.isMultiplayer = false,
  });

  /// Total number of cells in the grid.
  int get totalCells => gridColumns * gridRows;

  /// True if the grid is perfectly square.
  bool get isSquare => gridColumns == gridRows;

  /// Aspect ratio for the grid viewport (width / height).
  double get aspectRatio => gridColumns / gridRows;

  /// Backward-compat alias used by legacy code paths.
  int get gridSize => gridColumns;

  /// Calculate the Dynamic Opal Cost for this session.
  int calculateOpalCost({bool isPremiumAudio = false}) {
    double baseCost = (gridColumns * gridRows * 0.5) + (sessionDuration.inMinutes * 5.0);

    // Apply cooperative multiplier
    if (isMultiplayer) {
      baseCost *= 1.3;
    }

    // Add premium audio flat fee
    if (isPremiumAudio) {
      baseCost += 20;
    }

    return baseCost.round();
  }
}
