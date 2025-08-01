import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads_service.dart';

class AdaptiveBannerAdWidget extends StatefulWidget {
  const AdaptiveBannerAdWidget({super.key});

  @override
  State<AdaptiveBannerAdWidget> createState() => _AdaptiveBannerAdWidgetState();
}

class _AdaptiveBannerAdWidgetState extends State<AdaptiveBannerAdWidget> {
  final AdsService _adsService = AdsService();
  BannerAd? _adaptiveBannerAd;
  bool _isAdLoaded = false;
  AdSize? _adSize;

  @override
  void initState() {
    super.initState();
    _loadAdaptiveBannerAd();
  }

  Future<void> _loadAdaptiveBannerAd() async {
    if (kIsWeb || !_adsService.areAdsEnabled || !_adsService.hasBannerAdId) {
      return;
    }

    // Get the device width
    final MediaQueryData mediaQuery = MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.first);
    final double screenWidth = mediaQuery.size.width;
    final int adWidth = screenWidth.truncate();

    // Get adaptive banner ad size
    _adSize = await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      adWidth,
    );

    if (_adSize == null) {
      debugPrint('Unable to get adaptive banner ad size');
      return;
    }

    // Create adaptive banner ad
    _adaptiveBannerAd = BannerAd(
      adUnitId: _adsService.bannerAdUnitId,
      size: _adSize!,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Adaptive banner ad loaded.');
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Adaptive banner ad failed to load: $err');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }
        },
      ),
    );

    await _adaptiveBannerAd!.load();
  }

  @override
  void dispose() {
    _adaptiveBannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !_adsService.areAdsEnabled || !_isAdLoaded || _adaptiveBannerAd == null || _adSize == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
        border: Border.all(
          color: const Color(0xFF00D4AA).withOpacity(0.3),
          width: 0.3,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: SizedBox(
          width: _adSize!.width.toDouble(),
          height: _adSize!.height.toDouble(),
          child: AdWidget(ad: _adaptiveBannerAd!),
        ),
      ),
    );
  }
}