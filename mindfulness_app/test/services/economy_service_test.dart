import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulness_app/services/economy_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('EconomyService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('New user starts with 100 Opals and is not premium', () async {
      // We will inject a mock Supabase client or simply test the local logic first
      // Assuming EconomyService handles local state fallback
      final economyService = EconomyService();
      await economyService.init();

      expect(economyService.state.opals, 100);
      expect(economyService.state.isPremium, false);
    });
  });
}
