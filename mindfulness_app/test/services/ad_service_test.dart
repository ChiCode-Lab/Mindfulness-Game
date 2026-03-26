import 'package:flutter_test/flutter_test.dart';
import 'package:mindaware/services/ad_service.dart';

void main() {
  group('AdService', () {
    test('showRewardedAd calls onFailed when no ad is loaded', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      
      bool failedCalled = false;
      bool rewardedCalled = false;

      // AdService not initialized — _rewardedAd is null
      await AdService().showRewardedAd(
        onRewarded: () => rewardedCalled = true,
        onFailed: () => failedCalled = true,
      );

      expect(failedCalled, true);
      expect(rewardedCalled, false);
    });
  });
}
