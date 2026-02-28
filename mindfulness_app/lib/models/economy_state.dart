class EconomyState {
  final int opals;
  final DateTime? premiumTrialEnd;

  EconomyState({
    required this.opals,
    this.premiumTrialEnd,
  });

  bool get isPremium {
    if (premiumTrialEnd == null) return false;
    return DateTime.now().isBefore(premiumTrialEnd!);
  }

  factory EconomyState.initial() {
    return EconomyState(opals: 100);
  }

  factory EconomyState.fromJson(Map<String, dynamic> json) {
    return EconomyState(
      opals: json['opals_balance'] as int? ?? 100,
      premiumTrialEnd: json['premium_trial_end'] != null 
          ? DateTime.parse(json['premium_trial_end']) 
          : null,
    );
  }

  EconomyState copyWith({
    int? opals,
    DateTime? premiumTrialEnd,
  }) {
    return EconomyState(
      opals: opals ?? this.opals,
      premiumTrialEnd: premiumTrialEnd ?? this.premiumTrialEnd,
    );
  }
}
