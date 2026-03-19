import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';

/// Wraps the Google Mobile Ads SDK.
/// Follows the singleton pattern of EconomyService and NotificationService.
/// 
/// NEVER call showRewardedAd or showInterstitialAd for premium users —
/// callers are responsible for the isPremium guard.
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _isRewardedLoading = false;

  String get _rewardedAdUnitId => Platform.isIOS
      ? AdConfig.iosRewardedAdUnitId
      : AdConfig.androidRewardedAdUnitId;

  String get _interstitialAdUnitId => Platform.isIOS
      ? AdConfig.iosInterstitialAdUnitId
      : AdConfig.androidInterstitialAdUnitId;

  /// Initialize the SDK and pre-load first rewarded ad.
  /// Call once from main() after WidgetsFlutterBinding.ensureInitialized().
  Future<void> init() async {
    if (kIsWeb) return; // AdMob not supported on web
    await MobileAds.instance.initialize();
    _loadRewardedAd();
    _loadInterstitialAd();
  }

  void _loadRewardedAd() {
    if (_isRewardedLoading) return;
    _isRewardedLoading = true;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
          debugPrint('✅ AdService: Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          _isRewardedLoading = false;
          debugPrint('🔴 AdService: Rewarded ad failed: ${error.message}');
          // Retry after delay — prevents tight loop on no connectivity
          Future.delayed(const Duration(seconds: 30), _loadRewardedAd);
        },
      ),
    );
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          debugPrint('✅ AdService: Interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('🔴 AdService: Interstitial failed: ${error.message}');
        },
      ),
    );
  }

  /// Show the rewarded ad. Calls [onRewarded] if user earns the reward.
  /// Calls [onFailed] if no ad is available (graceful fallback).
  Future<void> showRewardedAd({
    required VoidCallback onRewarded,
    required VoidCallback onFailed,
  }) async {
    if (_rewardedAd == null) {
      debugPrint('AdService: No rewarded ad ready — calling onFailed');
      onFailed();
      _loadRewardedAd(); // Pre-load for next time
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd(); // Pre-load next ad immediately after dismiss
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        onFailed();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onRewarded();
      },
    );
  }

  /// Show an interstitial ad (optional pre-session friction for free users).
  /// Silently skips if no ad is loaded — never blocks the user flow.
  Future<void> showInterstitialAd() async {
    if (_interstitialAd == null) return;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
      },
    );

    await _interstitialAd!.show();
  }

  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
  }
}
