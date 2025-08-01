import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads_service.dart';
import '../services/app_update_service.dart';
import 'banner_ad_widget.dart';


class AdManagementWidget extends StatefulWidget {
  const AdManagementWidget({super.key});

  @override
  State<AdManagementWidget> createState() => _AdManagementWidgetState();
}

class _AdManagementWidgetState extends State<AdManagementWidget> {
  final AdsService _adsService = AdsService();
  final AppUpdateService _appUpdateService = AppUpdateService();
  String _selectedAdType = 'banner';

  @override
  void initState() {
    super.initState();
    _adsService.initialize();
    _checkForUpdates();
  }

  void _checkForUpdates() async {
    await _appUpdateService.checkForUpdate(context);
  }

  void _showInterstitialAd() {
    _adsService.showInterstitialAd();
  }

  void _showSecondInterstitialAd() {
    _adsService.showInterstitialAd(
      onAdClosed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Interstitial ad closed!'),
            backgroundColor: Color(0xFF00D4AA),
          ),
        );
      },
    );
  }


  void _showAppOpenAd() {
    _adsService.showAppOpenAd();
  }

  void _showUpdateDialog() {
    _appUpdateService.showUpdateDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad Management'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF1A1A1A),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ad Type Selection
            Card(
              color: const Color(0xFF2A2A2A),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Ad Type',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildAdTypeChip('banner', 'Banner Ad'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ad Display Area
            Card(
              color: const Color(0xFF2A2A2A),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ad Preview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSelectedAdWidget(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Card(
              color: const Color(0xFF2A2A2A),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ad Actions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.5,
                      children: [
                        _buildActionButton(
                          'Show Interstitial',
                          Icons.fullscreen,
                          _showInterstitialAd,
                        ),
                        _buildActionButton(
                          'Show Interstitial 2',
                          Icons.fullscreen_exit,
                          _showSecondInterstitialAd,
                        ),
                        _buildActionButton(
                          'Show App Open',
                          Icons.open_in_new,
                          _showAppOpenAd,
                        ),
                        _buildActionButton(
                          'Check Update',
                          Icons.system_update,
                          _showUpdateDialog,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdTypeChip(String type, String label) {
    final isSelected = _selectedAdType == type;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedAdType = type;
        });
      },
      backgroundColor: const Color(0xFF3A3A3A),
      selectedColor: const Color(0xFF00D4AA),
      checkmarkColor: Colors.black,
    );
  }

  Widget _buildSelectedAdWidget() {
    switch (_selectedAdType) {
      case 'banner':
        return const BannerAdWidget();
      default:
        return const BannerAdWidget();
    }
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00D4AA),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
    );
  }
}