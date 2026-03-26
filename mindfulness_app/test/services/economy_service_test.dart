import 'package:flutter_test/flutter_test.dart';
import 'package:mindaware/services/economy_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    // SharedPreferences mock MUST come before Supabase.initialize().
    // Supabase uses SharedPreferences internally for its auth session storage.
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://dummy.supabase.co',
        anonKey: 'dummy_key',
      );
    } catch (_) {
      // Already initialized in another test suite — safe to ignore.
    }
  });

  group('EconomyService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('New user starts with 100 Opals and is not premium', () async {
      // EconomyService.init() loads from local SharedPreferences first,
      // then async-syncs with Supabase (no user logged in = no-op in tests).
      final economyService = EconomyService();
      await economyService.init();

      expect(economyService.state.opals, 100);
      expect(economyService.state.isPremium, false);
    });

    test('Deducting opals reduces the balance correctly', () async {
      final economyService = EconomyService();
      await economyService.init();

      final success = await economyService.deductOpals(30);
      expect(success, true);
      expect(economyService.state.opals, 70);
    });

    test('Cannot deduct more opals than the balance', () async {
      final economyService = EconomyService();
      await economyService.init();

      final success = await economyService.deductOpals(200);
      expect(success, false);
      expect(economyService.state.opals, 100); // unchanged
    });

    test('Adding opals increases the balance', () async {
      final economyService = EconomyService();
      await economyService.init();

      await economyService.addOpals(50);
      expect(economyService.state.opals, 150);
    });
  });
}
