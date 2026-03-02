import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/economy_state.dart';

class EconomyService {
  // Lazy getter — not accessed until _syncWithSupabase() / deductOpals() etc.
  // This avoids a crash if EconomyService is instantiated before Supabase.initialize().
  SupabaseClient get _supabase => Supabase.instance.client;
  EconomyState _state = EconomyState.initial();


  EconomyState get state => _state;

  Future<void> init() async {
    // Attempt to load from local first for fast boot
    final prefs = await SharedPreferences.getInstance();
    final localOpals = prefs.getInt('local_opals');
    final localPremiumEnd = prefs.getString('local_premium_trial_end');
    
    if (localOpals != null) {
      _state = EconomyState(
        opals: localOpals,
        premiumTrialEnd: localPremiumEnd != null ? DateTime.parse(localPremiumEnd) : null,
      );
    }
    
    // Then async sync with Supabase if logged in
    _syncWithSupabase();
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
    if (_state.premiumTrialEnd != null) {
      await prefs.setString('local_premium_trial_end', _state.premiumTrialEnd!.toIso8601String());
    }
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
