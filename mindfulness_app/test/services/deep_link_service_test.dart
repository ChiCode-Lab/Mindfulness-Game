import 'package:flutter_test/flutter_test.dart';
import 'package:mindaware/services/deep_link_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('DeepLinkService', () {
    test('Parses invite room id and referral id from mindaware.app/invite url', () {
      final service = DeepLinkService();
      final result = service.parseIncomingUrl('mindaware.app/invite/abc-123?ref=usr_999');
      
      expect(result.roomId, 'abc-123');
      expect(result.referrerId, 'usr_999');
    });

    test('Ignores invalid paths without crashing', () {
      final service = DeepLinkService();
      final result = service.parseIncomingUrl('mindaware.app/dashboard');
      
      expect(result.roomId, isNull);
      expect(result.referrerId, isNull);
    });

    test('Handles https scheme directly', () {
      final service = DeepLinkService();
      final result = service.parseIncomingUrl('https://mindaware.app/invite/xyz-789');
      
      expect(result.roomId, 'xyz-789');
      expect(result.referrerId, isNull);
    });
  });
}
