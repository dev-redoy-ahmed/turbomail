import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  final AdsService _adsService = AdsService();

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    if (_adsService.areAdsEnabled) {
      _adsService.loadBannerAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if ads are disabled or not loaded
    if (!_adsService.areAdsEnabled || !_adsService.isBannerAdLoaded || _adsService.bannerAd == null) {
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
        child: Container(
          height: 60,
          child: AdWidget(ad: _adsService.bannerAd!),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Don't dispose the banner ad here as it might be used elsewhere
    super.dispose();
  }
}