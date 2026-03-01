class ZenTreeData {
  final DateTime date;
  int leafCount;
  int presenceLevel;

  ZenTreeData({
    required this.date,
    this.leafCount = 0,
    this.presenceLevel = 100, // Default to baseline
  });

  /// The visual growth scale of the tree.
  /// Grows until 2000 leaves, then caps.
  double get scaleFactor {
    // Clamping leaves for visual growth calculation only
    final growthLeaves = leafCount.clamp(0, 2000);
    // Becomes 2.0 at 2000 leaves (starts at 0.5)
    return 0.5 + (1.5 * (growthLeaves / 2000.0));
  }

  /// The achieved daily presence level (max 100).
  int get focusScore => presenceLevel.clamp(0, 100);

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'leafCount': leafCount,
      'presenceLevel': presenceLevel,
    };
  }

  factory ZenTreeData.fromJson(Map<String, dynamic> json) {
    return ZenTreeData(
      date: DateTime.parse(json['date']),
      leafCount: json['leafCount'] ?? 0,
      presenceLevel: json['presenceLevel'] ?? 100,
    );
  }
}
