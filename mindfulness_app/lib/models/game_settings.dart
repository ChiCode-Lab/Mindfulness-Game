enum Soundscape {
  rainThunder,
  oceanWaves,
  campfire,
  forestUnderwater,
  none,
}

class GameSettings {
  int gridSize; // e.g., 2 for 2x2, 3 for 3x3, 4 for 4x4
  Duration sessionDuration;
  Soundscape soundscape;
  bool isMultiplayer;

  GameSettings({
    this.gridSize = 4,
    this.sessionDuration = const Duration(minutes: 5),
    this.soundscape = Soundscape.none,
    this.isMultiplayer = false,
  });

  // Calculate the total number of cells based on grid size
  int get totalCells => gridSize * gridSize;

  // Calculate the Dynamic Opal Cost for this session
  int calculateOpalCost({bool isPremiumAudio = false}) {
    double baseCost = (gridSize * 2.0) + (sessionDuration.inMinutes * 5.0);
    
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

