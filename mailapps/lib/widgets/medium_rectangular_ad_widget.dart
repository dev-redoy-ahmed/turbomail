import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads_service.dart';

class MediumRectangularAdWidget extends StatefulWidget {
  const MediumRectangularAdWidget({super.key});

  @override
  State<MediumRectangularAdWidget> createState() => _MediumRectangularAdWidgetState();
}

class _MediumRectangularAdWidgetState extends State<MediumRectangularAdWidget> {
  final AdsService _adsService = AdsService();
  BannerAd? _mediumRectangularAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMediumRectangularAd();
  }
 
  void _loadMediumRectangularAd() {
    if (kIsWeb || !_adsService.areAdsEnabled || !_adsService.hasBannerAdId) {
      return;
    }

    // Create a separate banner ad instance for medium rectangle size
    _mediumRectangularAd = BannerAd(
      adUnitId: _adsService.bannerAdUnitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Medium rectangular ad loaded.');
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Medium rectangular ad failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }
        },
      ),
    );
    _mediumRectangularAd!.load();
  }

  @override
  void dispose() {
    _mediumRectangularAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !_adsService.areAdsEnabled || !_isAdLoaded || _mediumRectangularAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00D4AA).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: AdSize.mediumRectangle.width.toDouble(),
          height: AdSize.mediumRectangle.height.toDouble(),
          child: AdWidget(ad: _mediumRectangularAd!),
        ),
      ),
    );
  }
}