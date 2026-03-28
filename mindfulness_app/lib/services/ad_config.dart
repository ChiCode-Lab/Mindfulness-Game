// Safe for GitHub - pulls real Ad Unit IDs from environment, defaults to Test Ads.
// AdMob App ID (ca-app-pub-XXXX~YYYY) must also be updated in AndroidManifest.xml.

class AdConfig {
  // Android production Ad Unit IDs
  static const String androidInterstitialAdUnitId =
      String.fromEnvironment('ADMOB_ANDROID_INTERSTITIAL', defaultValue: 'ca-app-pub-3940256099942544/1033173712');
  static const String androidRewardedAdUnitId =
      String.fromEnvironment('ADMOB_ANDROID_REWARDED', defaultValue: 'ca-app-pub-3940256099942544/5224354917');

  // iOS production Ad Unit IDs
  static const String iosInterstitialAdUnitId =
      String.fromEnvironment('ADMOB_IOS_INTERSTITIAL', defaultValue: 'ca-app-pub-3940256099942544/4411468910');
  static const String iosRewardedAdUnitId =
      String.fromEnvironment('ADMOB_IOS_REWARDED', defaultValue: 'ca-app-pub-3940256099942544/1712485313');
}
