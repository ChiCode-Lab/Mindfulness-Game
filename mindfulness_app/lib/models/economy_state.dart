enum PremiumSource { none, trial, revenuecat }

class EconomyState {
  final int opals;
  final DateTime? premiumTrialEnd;
  final bool isPaidSubscriber;
  final PremiumSource premiumSource;

  EconomyState({
    required this.opals,
    this.premiumTrialEnd,
    this.isPaidSubscriber = false,
    this.premiumSource = PremiumSource.none,
  });

  // isPremium is true if EITHER the trial is active OR a paid
  // subscription is active. All app-level checks use this single getter.
  bool get isPremium {
    final trialActive = premiumTrialEnd != null &&
        DateTime.now().isBefore(premiumTrialEnd!);
    return trialActive || isPaidSubscriber;
  }

  // Convenience getter used by PaywallScreen and nudge widgets
  // to distinguish trial users from paid subscribers.
  bool get isOnTrial =>
      premiumTrialEnd != null &&
      DateTime.now().isBefore(premiumTrialEnd!) &&
      !isPaidSubscriber;

  // How many days remain in the trial. Returns 0 if not on trial.
  int get trialDaysRemaining {
    if (premiumTrialEnd == null) return 0;
    final remaining = premiumTrialEnd!.difference(DateTime.now()).inDays;
    return remaining.clamp(0, 5);
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
      isPaidSubscriber: json['is_paid_subscriber'] as bool? ?? false,
      premiumSource: parsePremiumSource(
        json['premium_source'] as String? ?? 'none',
      ),
    );
  }

  static PremiumSource parsePremiumSource(String value) {
    switch (value) {
      case 'trial':
        return PremiumSource.trial;
      case 'revenuecat':
        return PremiumSource.revenuecat;
      default:
        return PremiumSource.none;
    }
  }

  EconomyState copyWith({
    int? opals,
    DateTime? premiumTrialEnd,
    bool? isPaidSubscriber,
    PremiumSource? premiumSource,
  }) {
    return EconomyState(
      opals: opals ?? this.opals,
      premiumTrialEnd: premiumTrialEnd ?? this.premiumTrialEnd,
      isPaidSubscriber: isPaidSubscriber ?? this.isPaidSubscriber,
      premiumSource: premiumSource ?? this.premiumSource,
    );
  }
}
