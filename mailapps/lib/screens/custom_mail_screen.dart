import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/email_provider.dart';
import '../providers/premium_provider.dart';
import '../services/ads_service.dart';
import '../utils/page_transitions.dart';
import 'premium_screen.dart';
import '../widgets/banner_ad_widget.dart';

class CustomMailScreen extends StatefulWidget {
  const CustomMailScreen({super.key});

  @override
  State<CustomMailScreen> createState() => _CustomMailScreenState();
}

class _CustomMailScreenState extends State<CustomMailScreen> with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  String _selectedDomain = 'oplex.online';
  bool _isCreating = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1C2E),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            _buildCustomAppBar(),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Hero Section
                      _buildHeroSection(),

                      const SizedBox(height: 30),

                      // Custom Email Creation Form
                      _buildCustomEmailForm(),

                      const SizedBox(height: 30),

                      // Current Email Display (if exists)
                      _buildCurrentEmailDisplay(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            // Banner ad at bottom
            Consumer<PremiumProvider>(
              builder: (context, premiumProvider, child) {
                if (!premiumProvider.isPremium) {
                  return const BannerAdWidget();
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF1A2434),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF00D4AA).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF00D4AA),
                  size: 16,
                ),
              ),
            ),
            const Expanded(
              child: Text(
                'Custom Email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF00D4AA).withOpacity(0.1),
                const Color(0xFF00A693).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00D4AA).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D4AA), Color(0xFF00A693)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4AA).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.alternate_email,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Create Custom Email',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose your own username and domain',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomEmailForm() {
    return Consumer<EmailProvider>(
      builder: (context, emailProvider, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2434),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00D4AA).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username Input
              const Text(
                'Username',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1C2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00D4AA).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter username',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: const Color(0xFF00D4AA),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Domain Selection
              const Text(
                'Domain',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1C2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00D4AA).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDomain,
                    dropdownColor: const Color(0xFF1A2434),
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF00D4AA),
                    ),
                    items: emailProvider.availableDomains.map((domain) {
                      return DropdownMenuItem(
                        value: domain,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.language,
                              color: Color(0xFF00D4AA),
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(domain),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDomain = value!;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createCustomEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4AA),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Create Custom Email',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentEmailDisplay() {
    return Consumer<EmailProvider>(
      builder: (context, emailProvider, child) {
        if (emailProvider.currentEmail == null) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2434),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00D4AA).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF00D4AA),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Active Email',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1C2E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF00D4AA).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  emailProvider.currentEmail!,
                  style: const TextStyle(
                    color: Color(0xFF00D4AA),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _createCustomEmail() async {
    if (_usernameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a username');
      return;
    }

    final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);
    
    // Check if user is premium
    if (!premiumProvider.isPremium) {
      // Show premium/ad popup for non-premium users
      final result = await _showPremiumOrAdDialog();
      if (result == null) return; // User cancelled
      
      if (result == 'premium') {
        // Navigate to premium screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PremiumScreen()),
        );
        return;
      } else if (result == 'ad') {
         // Show interstitial ad
         final adsService = AdsService();
         
         adsService.showInterstitialAd(
           onAdClosed: () {
             // Continue with email creation after ad is closed
           },
         );
         
         // If no ad available, continue anyway
         if (!adsService.isInterstitialAdLoaded) {
           // Continue with email creation
         }
       }
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final emailProvider = Provider.of<EmailProvider>(context, listen: false);
      await emailProvider.generateManualEmail(
        _usernameController.text.trim().toLowerCase(),
        _selectedDomain,
      );

      _showSuccessSnackBar('Custom email created successfully!');
      _usernameController.clear();
    } catch (e) {
      _showErrorSnackBar('Failed to create email: ${e.toString()}');
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  Future<String?> _showPremiumOrAdDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2434),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.star, color: Color(0xFF00D4AA)),
            SizedBox(width: 8),
            Text(
              'Premium Feature',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custom email creation is a premium feature.',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 12),
            Text(
              'Choose an option to continue:',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'ad'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Watch Ad'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'premium'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
              foregroundColor: Colors.white,
            ),
            child: const Text('Buy Premium'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00D4AA),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }


}