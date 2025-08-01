import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AdsService {
  static final AdsService _instance = AdsService._internal();
  factory AdsService() => _instance;
  AdsService._internal();

  final ApiService _apiService = ApiService();
  AdConfig? _adConfig;

  // Ad instances
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  AppOpenAd? _appOpenAd;

  // Ad loading states
  bool _isBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isRewardedAdLoaded = false;
  bool _isAppOpenAdLoaded = false;
  bool _isShowingAppOpenAd = false;

  // Cache keys for current session storage
  static const String _adConfigCacheKey = 'ad_config_cache';
  static const String _adConfigTimestampKey = 'ad_config_timestamp';

  // Load fresh ad configuration from API every time
  Future<void> _loadAdConfig() async {
    try {
      debugPrint('Loading fresh ad configuration from API...');
      
      // Always fetch fresh data from API
      _adConfig = await _apiService.getAdConfig();
      
      // Store to cache for current session only
      await _saveToCache(_adConfig!);
      
      debugPrint('Fresh ad configuration loaded and stored: ${_adConfig?.adsEnabled}');
      _logAdIds();
    } catch (e) {
      debugPrint('Failed to load fresh ad config: $e');
      
      // Use default test ad configuration as fallback
      _adConfig = AdConfig.fromJson({});
      debugPrint('Using default test ad configuration');
    }
  }
  
  // Helper method to log ad IDs
  void _logAdIds() {
    if (_adConfig?.adsEnabled == true) {
      debugPrint('Ad IDs loaded:');
      debugPrint('  Banner: ${_adConfig!.bannerId.isNotEmpty ? "✓" : "✗"}');
      debugPrint('  Interstitial: ${_adConfig!.interstitialId.isNotEmpty ? "✓" : "✗"}');
      debugPrint('  Rewarded: ${_adConfig!.rewardedId.isNotEmpty ? "✓" : "✗"}');

      debugPrint('  App Open: ${_adConfig!.appOpenId.isNotEmpty ? "✓" : "✗"}');
    }
  }
  
  // Clear ad configuration cache
  Future<void> clearAdCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_adConfigCacheKey);
      await prefs.remove(_adConfigTimestampKey);
      debugPrint('Ad configuration cache cleared successfully');
    } catch (e) {
      debugPrint('Error clearing ad cache: $e');
    }
  }
  
  // Save ad config to cache
  Future<void> _saveToCache(AdConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = jsonEncode(config.toJson());
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      await prefs.setString(_adConfigCacheKey, configJson);
      await prefs.setInt(_adConfigTimestampKey, timestamp);
      
      debugPrint('Ad configuration cached successfully');
    } catch (e) {
      debugPrint('Error saving to cache: $e');
    }
  }

  // Check if ads are enabled and API config is available
  bool get areAdsEnabled => _adConfig?.adsEnabled == true && _adConfig != null;

  // Check if specific ad types have valid IDs from API
  bool get hasBannerAdId {
    if (_adConfig == null) return false;
    return _adConfig!.bannerId.isNotEmpty;
  }
  
  bool get hasInterstitialAdId {
    if (_adConfig == null) return false;
    return _adConfig!.interstitialId.isNotEmpty;
  }
  
  bool get hasRewardedAdId {
    if (_adConfig == null) return false;
    return _adConfig!.rewardedId.isNotEmpty;
  }
  

  
  bool get hasAppOpenAdId {
    if (_adConfig == null) return false;
    return _adConfig!.appOpenId.isNotEmpty;
  }

  // Get ad unit IDs
  String get _bannerAdUnitId => _adConfig!.bannerId;
  String get _interstitialAdUnitId => _adConfig!.interstitialId;
  String get _rewardedAdUnitId => _adConfig!.rewardedId;

  String get _appOpenAdUnitId => _adConfig!.appOpenId;
  
  // Public getter for banner ad unit ID
  String get bannerAdUnitId => _bannerAdUnitId;

  // Refresh ad configuration from API
  Future<void> refreshAdConfig() async {
    debugPrint('Refreshing ad configuration...');
    await _apiService.refreshCache();
    await _loadAdConfig();
    
    if (areAdsEnabled) {
      debugPrint('Reloading ads with new configuration...');
      
      // Dispose existing ads
      disposeBannerAd();
      _disposeInterstitialAd();
      _disposeRewardedAd();
      _disposeAppOpenAd();
      
      // Reload ads with new configuration
      if (hasBannerAdId) {
        loadBannerAd();
      }
      if (hasInterstitialAdId) {
        loadInterstitialAd();
      }
      if (hasRewardedAdId) {
        loadRewardedAd();
      }
      if (hasAppOpenAdId) {
        loadAppOpenAd();
      }
    }
  }

  // Helper methods to dispose ads
  void _disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdLoaded = false;
  }

  void _disposeRewardedAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdLoaded = false;
  }

  void _disposeAppOpenAd() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isAppOpenAdLoaded = false;
  }

  // Initialize Mobile Ads SDK
  Future<void> initialize() async {
    // Skip ads initialization on web platform
    if (kIsWeb) {
      debugPrint('Skipping Mobile Ads SDK initialization on web platform');
      await _loadAdConfig();
      return;
    }
    
    debugPrint('Initializing Mobile Ads SDK...');
    await MobileAds.instance.initialize();
    debugPrint('Mobile Ads SDK initialized');
    
    await _loadAdConfig();
    
    if (areAdsEnabled) {
      debugPrint('Ads are enabled, preloading ads...');
      
      // Preload all ad types
      if (hasBannerAdId) {
        loadBannerAd();
      }
      if (hasInterstitialAdId) {
        loadInterstitialAd();
      }
      if (hasRewardedAdId) {
        loadRewardedAd();
      }
      if (hasAppOpenAdId) {
        loadAppOpenAd();
      }
      
      debugPrint('Ad preloading initiated');
    } else {
      debugPrint('Ads are disabled or no valid ad IDs found');
    }
  }

  // Banner Ad Methods
  void loadBannerAd() {
    if (kIsWeb || !areAdsEnabled || !hasBannerAdId) return;
    
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded.');
          _isBannerAdLoaded = true;
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Banner ad failed to load: $err');
          ad.dispose();
          _isBannerAdLoaded = false;
        },
      ),
    );
    _bannerAd!.load();
  }

  BannerAd? get bannerAd => _bannerAd;
  bool get isBannerAdLoaded => _isBannerAdLoaded;

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }

  // Interstitial Ad Methods
  void loadInterstitialAd() {
    if (kIsWeb || !areAdsEnabled || !hasInterstitialAdId) return;
    
    InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial ad loaded.');
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (err) {
          debugPrint('Interstitial ad failed to load: $err');
          _interstitialAd = null;
          _isInterstitialAdLoaded = false;
        },
      ),
    );
  }

  void showInterstitialAd({VoidCallback? onAdClosed}) {
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('Interstitial ad showed full screen content.');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('Interstitial ad dismissed.');
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialAdLoaded = false;
          onAdClosed?.call();
          loadInterstitialAd(); // Load next ad
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          debugPrint('Interstitial ad failed to show: $err');
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialAdLoaded = false;
          onAdClosed?.call();
        },
      );
      _interstitialAd!.show();
    } else {
      debugPrint('Interstitial ad not ready.');
      onAdClosed?.call();
    }
  }

  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;

  // Rewarded Ad Methods
  void loadRewardedAd() {
    if (kIsWeb || !areAdsEnabled || !hasRewardedAdId) return;
    
    RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Rewarded ad loaded.');
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
        },
        onAdFailedToLoad: (err) {
          debugPrint('Rewarded ad failed to load: $err');
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
        },
      ),
    );
  }

  void showRewardedAd({
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdClosed,
  }) {
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('Rewarded ad showed full screen content.');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('Rewarded ad dismissed.');
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
          onAdClosed?.call();
          loadRewardedAd(); // Load next ad
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          debugPrint('Rewarded ad failed to show: $err');
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
          onAdClosed?.call();
        },
      );

      _rewardedAd!.setImmersiveMode(true);
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          onUserEarnedReward();
        },
      );
    } else {
      debugPrint('Rewarded ad not ready.');
      onAdClosed?.call();
    }
  }

  bool get isRewardedAdLoaded => _isRewardedAdLoaded;



  // App Open Ad Methods
  void loadAppOpenAd() {
    if (kIsWeb || !areAdsEnabled || !hasAppOpenAdId) return;
    
    AppOpenAd.load(
        adUnitId: _appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('App open ad loaded.');
          _appOpenAd = ad;
          _isAppOpenAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('App open ad failed to load: $error');
          _appOpenAd = null;
          _isAppOpenAdLoaded = false;
        },
      ),
    );
  }

  void showAppOpenAd() {
    if (_isAppOpenAdLoaded && _appOpenAd != null && !_isShowingAppOpenAd) {
      _isShowingAppOpenAd = true;
      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('App open ad showed full screen content.');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('App open ad dismissed.');
          _isShowingAppOpenAd = false;
          ad.dispose();
          _appOpenAd = null;
          _isAppOpenAdLoaded = false;
          loadAppOpenAd(); // Load next ad
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('App open ad failed to show: $error');
          _isShowingAppOpenAd = false;
          ad.dispose();
          _appOpenAd = null;
          _isAppOpenAdLoaded = false;
        },
      );
      _appOpenAd!.show();
    }
  }

  bool get isAppOpenAdLoaded => _isAppOpenAdLoaded;
  bool get isShowingAppOpenAd => _isShowingAppOpenAd;

  // Load all ads
  void loadAllAds() {
    if (kIsWeb || !areAdsEnabled) return;
    
    loadBannerAd();
    loadInterstitialAd();
    loadRewardedAd();
    loadAppOpenAd();
  }

  // Dispose all ads
  void disposeAllAds() {
    disposeBannerAd();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _appOpenAd?.dispose();
  }
}