import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/economy_state.dart';
import 'subscription_service.dart';

class EconomyService {
  // Lazy getter — not accessed until _syncWithSupabase() / deductOpals() etc.
  // This avoids a crash if EconomyService is instantiated before Supabase.initialize().
  SupabaseClient get _supabase => Supabase.instance.client;
  EconomyState _state = EconomyState.initial();


  EconomyState get state => _state;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final localOpals = prefs.getInt('local_opals');
    final localPremiumEnd = prefs.getString('local_premium_trial_end');
    final localIsPaid = prefs.getBool('local_is_paid_subscriber') ?? false;
    final localPremiumSource = prefs.getString('local_premium_source') ?? 'none';

    if (localOpals != null) {
      _state = EconomyState(
        opals: localOpals,
        premiumTrialEnd: localPremiumEnd != null
            ? DateTime.parse(localPremiumEnd)
            : null,
        isPaidSubscriber: localIsPaid,
        premiumSource: EconomyState.parsePremiumSource(localPremiumSource),
      );
    }

    // Sync both Supabase economy data and RevenueCat entitlement in parallel.
    // Neither blocks the other — both update state independently.
    _syncWithSupabase();
    syncSubscriptionStatus();
  }

  Future<void> _syncWithSupabase() async {
    final user = _supabase.auth.currentSession?.user;
    if (user != null) {
      try {
        final data = await _supabase
            .from('user_economy')
            .select()
            .eq('id', user.id)
            .maybeSingle();
            
        if (data != null) {
          _state = EconomyState.fromJson(data);
          _saveLocalState();
        }
      } catch (e) {
        // Fallback to local state if offline or error
        print("Supabase economy sync failed: \$e");
      }
    }
  }

  Future<void> _saveLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('local_opals', _state.opals);
    await prefs.setBool('local_is_paid_subscriber', _state.isPaidSubscriber);
    await prefs.setString('local_premium_source', _state.premiumSource.name);
    if (_state.premiumTrialEnd != null) {
      await prefs.setString(
        'local_premium_trial_end',
        _state.premiumTrialEnd!.toIso8601String(),
      );
    }
  }

  // Pulls current RevenueCat entitlement and updates both local state
  // and Supabase. Called on init() and from PaywallScreen after purchase.
  Future<void> syncSubscriptionStatus() async {
    final isActive = await SubscriptionService().isPremiumActive();
    final productId = await SubscriptionService().activeProductId();

    final source = isActive ? PremiumSource.revenuecat : PremiumSource.none;

    _state = _state.copyWith(
      isPaidSubscriber: isActive,
      premiumSource: source,
    );
    await _saveLocalState();

    final user = _supabase.auth.currentSession?.user;
    if (user != null) {
      await _supabase.from('user_economy').update({
        'is_paid_subscriber': isActive,
        'premium_source': source.name,
        'subscription_status': isActive ? 'active' : 'free',
      }).eq('id', user.id);
    }

    debugPrint(
      'EconomyService: RC sync — isPaid: $isActive, product: $productId',
    );
  }

  // Streak-scaling daily Opal reward. Called once per calendar day on
  // app open. Guard prevents double-claiming on the same day.
  Future<int> claimDailyOpalReward(int currentStreak) async {
    final prefs = await SharedPreferences.getInstance();
    final lastClaimStr = prefs.getString('last_daily_opal_claim');

    if (lastClaimStr != null) {
      final lastClaim = DateTime.parse(lastClaimStr);
      final today = DateTime.now();
      final isSameDay = lastClaim.year == today.year &&
          lastClaim.month == today.month &&
          lastClaim.day == today.day;
      if (isSameDay) return 0; // Already claimed today
    }

    final reward = _opalRewardForStreak(currentStreak);
    await addOpals(reward);
    await prefs.setString(
      'last_daily_opal_claim',
      DateTime.now().toIso8601String(),
    );

    debugPrint(
      'EconomyService: daily reward claimed — $reward Opals '
      '(streak: $currentStreak)',
    );
    return reward;
  }

  // Streak-scaling table from the subscription plan document.
  int _opalRewardForStreak(int streak) {
    if (streak >= 30) return 100;
    if (streak >= 14) return 50;
    if (streak >= 7)  return 35;
    return 20;
  }

  bool canAfford(int amount) {
    if (_state.isPremium) return true;
    return _state.opals >= amount;
  }

  Future<bool> deductOpals(int amount) async {
    if (_state.isPremium) return true;
    if (_state.opals < amount) return false;

    // Optimistic update
    _state = _state.copyWith(opals: _state.opals - amount);
    await _saveLocalState();

    final user = _supabase.auth.currentSession?.user;
    if (user != null) {
      try {
        await _supabase
            .from('user_economy')
            .update({'opals_balance': _state.opals})
            .eq('id', user.id);
      } catch (e) {
        print("Failed to sync deduction to Supabase: \$e");
      }
    }
    return true;
  }

  Future<void> addOpals(int amount) async {
    _state = _state.copyWith(opals: _state.opals + amount);
    await _saveLocalState();

    final user = _supabase.auth.currentSession?.user;
    if (user != null) {
      try {
        await _supabase
            .from('user_economy')
            .update({'opals_balance': _state.opals})
            .eq('id', user.id);
      } catch (e) {
        print("Failed to sync addition to Supabase: \$e");
      }
    }
  }

  Future<void> startPremiumTrial() async {
    final trialEnd = DateTime.now().add(const Duration(days: 5));
    _state = _state.copyWith(premiumTrialEnd: trialEnd);
    await _saveLocalState();

    final user = _supabase.auth.currentSession?.user;
    if (user != null) {
      try {
        await _supabase
            .from('user_economy')
            .update({'premium_trial_end': trialEnd.toIso8601String()})
            .eq('id', user.id);
      } catch (e) {
        print("Failed to sync premium trial to Supabase: \$e");
      }
    }
  }
}
