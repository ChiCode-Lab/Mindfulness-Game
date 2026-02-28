class GameMetrics {
  int correctTaps;
  int wrongTaps;
  List<Duration> reactionTimes;
  int treeGrowthLevel;
  int currentStreak;

  GameMetrics({
    this.correctTaps = 0,
    this.wrongTaps = 0,
    List<Duration>? reactionTimes,
    this.treeGrowthLevel = 0,
    this.currentStreak = 0,
  }) : reactionTimes = reactionTimes ?? [];

  int get totalTaps => correctTaps + wrongTaps;

  double get accuracy {
    if (totalTaps == 0) return 0.0;
    return correctTaps / totalTaps;
  }

  Duration get averageReactionTime {
    if (reactionTimes.isEmpty) return Duration.zero;
    final totalMicroseconds = reactionTimes.fold<int>(
      0,
      (sum, duration) => sum + duration.inMicroseconds,
    );
    return Duration(microseconds: totalMicroseconds ~/ reactionTimes.length);
  }

  void recordTap({required bool isCorrect, required Duration reactionTime}) {
    if (isCorrect) {
      correctTaps++;
      currentStreak++;
      // Every 5 correct taps in a row grows the tree
      if (currentStreak > 0 && currentStreak % 5 == 0) {
        treeGrowthLevel++;
      }
    } else {
      wrongTaps++;
      currentStreak = 0;
    }
    reactionTimes.add(reactionTime);
  }

  void reset() {
    correctTaps = 0;
    wrongTaps = 0;
    reactionTimes.clear();
    currentStreak = 0;
    treeGrowthLevel = 0;
  }
}
