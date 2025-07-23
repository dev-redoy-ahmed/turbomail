import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads_service.dart';

class AdBannerWidget extends StatefulWidget {
  final AdSize adSize;
  final EdgeInsets? margin;
  
  const AdBannerWidget({
    Key? key,
    this.adSize = AdSize.banner,
    this.margin,
  }) : super(key: key);

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  Future<void> _loadBannerAd() async {
    final bannerAd = await AdsService().loadBannerAd();
    if (bannerAd != null && mounted) {
      setState(() {
        _bannerAd = bannerAd;
        _isLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: widget.margin,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

class AdInterstitialHelper {
  static Future<void> showInterstitialAd({
    required VoidCallback onAdClosed,
    VoidCallback? onAdFailedToShow,
  }) async {
    try {
      final success = await AdsService().showInterstitialAd();
      if (success) {
        // Ad was shown successfully
        onAdClosed();
      } else {
        // Ad failed to show or not available
        onAdFailedToShow?.call();
        onAdClosed(); // Continue with the action anyway
      }
    } catch (e) {
      print('Error showing interstitial ad: $e');
      onAdFailedToShow?.call();
      onAdClosed(); // Continue with the action anyway
    }
  }
}

class AdRewardedHelper {
  static Future<void> showRewardedAd({
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdFailedToShow,
    VoidCallback? onAdClosed,
  }) async {
    try {
      final success = await AdsService().showRewardedAd(
        onUserEarnedReward: onUserEarnedReward,
      );
      if (!success) {
        onAdFailedToShow?.call();
      }
      onAdClosed?.call();
    } catch (e) {
      print('Error showing rewarded ad: $e');
      onAdFailedToShow?.call();
      onAdClosed?.call();
    }
  }
}

// Example usage in a screen
class ExampleScreenWithAds extends StatefulWidget {
  const ExampleScreenWithAds({Key? key}) : super(key: key);

  @override
  State<ExampleScreenWithAds> createState() => _ExampleScreenWithAdsState();
}

class _ExampleScreenWithAdsState extends State<ExampleScreenWithAds> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example with Ads'),
      ),
      body: Column(
        children: [
          // Banner ad at the top
          const AdBannerWidget(
            margin: EdgeInsets.all(8.0),
          ),
          
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Show interstitial ad before navigation
                      AdInterstitialHelper.showInterstitialAd(
                        onAdClosed: () {
                          // Navigate to next screen after ad
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AnotherScreen(),
                            ),
                          );
                        },
                        onAdFailedToShow: () {
                          print('Interstitial ad failed to show');
                        },
                      );
                    },
                    child: const Text('Navigate with Interstitial Ad'),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  ElevatedButton(
                    onPressed: () {
                      // Show rewarded ad for premium feature
                      AdRewardedHelper.showRewardedAd(
                        onUserEarnedReward: () {
                          // Grant premium feature
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reward earned! Premium feature unlocked.'),
                            ),
                          );
                        },
                        onAdFailedToShow: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ad not available. Try again later.'),
                            ),
                          );
                        },
                      );
                    },
                    child: const Text('Watch Ad for Reward'),
                  ),
                ],
              ),
            ),
          ),
          
          // Banner ad at the bottom
          const AdBannerWidget(
            margin: EdgeInsets.all(8.0),
          ),
        ],
      ),
    );
  }
}

class AnotherScreen extends StatelessWidget {
  const AnotherScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Another Screen'),
      ),
      body: const Center(
        child: Text('This screen was reached after showing an interstitial ad!'),
      ),
    );
  }
}