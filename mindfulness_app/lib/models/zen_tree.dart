class ZenTreeData {
  final DateTime date;
  int leafCount;

  ZenTreeData({
    required this.date,
    this.leafCount = 0,
  });

  // Calculate the visual scale multiplier of the tree based on leaf count
  // Assuming a max reasonable leaf count for a single session is ~50-100
  double get scaleFactor {
    // Starts at 0.5 scale, grows up to 1.5 scale asymptotically
    return 0.5 + (1.0 * (1 - (1 / (1 + (leafCount / 20)))));
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'leafCount': leafCount,
    };
  }

  factory ZenTreeData.fromJson(Map<String, dynamic> json) {
    return ZenTreeData(
      date: DateTime.parse(json['date']),
      leafCount: json['leafCount'] ?? 0,
    );
  }
}
