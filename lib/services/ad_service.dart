import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'platform_support.dart';
import 'revenue_cat_service.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  /// Live Production AdMob Ad Unit IDs
  static const String bannerIdAndroid = String.fromEnvironment(
    'ADMOB_BANNER',
    defaultValue: 'ca-app-pub-3744400504443798/1573738368',
  );
  static const String interstitialIdAndroid = String.fromEnvironment(
    'ADMOB_INTERSTITIAL',
    defaultValue: 'ca-app-pub-3744400504443798/7756003336',
  );
  static const String rewardedIdAndroid = String.fromEnvironment(
    'ADMOB_REWARDED',
    defaultValue: 'ca-app-pub-3744400504443798/5207615639',
  );
  static const String appOpenIdAndroid = String.fromEnvironment(
    'ADMOB_APP_OPEN',
    defaultValue: 'ca-app-pub-3744400504443798/1077154155',
  );

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  AppOpenAd? _appOpenAd;

  static const Duration interstitialFrequencyCap = Duration(hours: 1);
  DateTime? _lastInterstitialTime;

  Future<void> preloadAds() async {
    if (!PlatformSupport.supportsAds) return;
    if (RevenueCatService.instance.isProUser) return;
    loadInterstitialAd();
    loadRewardedAd();
    loadAppOpenAd();
  }

  void loadInterstitialAd() {
    if (!PlatformSupport.supportsAds) return;
    if (RevenueCatService.instance.isProUser) return;
    InterstitialAd.load(
      adUnitId: interstitialIdAndroid,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('Interstitial failed to load: $err');
          _interstitialAd = null;
        },
      ),
    );
  }

  bool showInterstitialIfAllowed() {
    if (!PlatformSupport.supportsAds) return false;
    if (RevenueCatService.instance.isProUser) return false;

    final now = DateTime.now();
    if (_lastInterstitialTime != null &&
        now.difference(_lastInterstitialTime!) < interstitialFrequencyCap) {
      debugPrint('Interstitial frequency cap active. Skipping ad.');
      return false;
    }

    if (_interstitialAd != null) {
      _lastInterstitialTime = now;
      _interstitialAd!.show();
      return true;
    }

    loadInterstitialAd();
    return false;
  }

  void loadRewardedAd() {
    if (!PlatformSupport.supportsAds) return;
    RewardedAd.load(
      adUnitId: rewardedIdAndroid,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (err) {
          debugPrint('Rewarded ad failed to load: $err');
          _rewardedAd = null;
        },
      ),
    );
  }

  void showRewardedAdForPdfExport({
    required VoidCallback onRewardEarned,
    required VoidCallback onFailed,
  }) {
    if (RevenueCatService.instance.isProUser || !PlatformSupport.supportsAds) {
      onRewardEarned();
      return;
    }

    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd();
          onFailed();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          onRewardEarned();
        },
      );
    } else {
      loadRewardedAd();
      onRewardEarned();
    }
  }

  void loadAppOpenAd() {
    if (!PlatformSupport.supportsAds) return;
    if (RevenueCatService.instance.isProUser) return;
    AppOpenAd.load(
      adUnitId: appOpenIdAndroid,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) => _appOpenAd = ad,
        onAdFailedToLoad: (err) => _appOpenAd = null,
      ),
    );
  }

  void showAppOpenAd() {
    if (!PlatformSupport.supportsAds) return;
    if (RevenueCatService.instance.isProUser) return;
    if (_lastInterstitialTime != null &&
        DateTime.now().difference(_lastInterstitialTime!) < const Duration(minutes: 5)) {
      return;
    }
    _appOpenAd?.show();
    _appOpenAd = null;
    loadAppOpenAd();
  }
}
