import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:turbomail/screens/premium_screen.dart';
import '../providers/email_provider.dart';
import '../providers/premium_provider.dart';
import '../services/ads_service.dart';
import '../services/app_update_service.dart';
import '../utils/page_transitions.dart';
import 'inbox_screen.dart';
import 'premium_screen.dart';
import 'custom_drawer.dart';
import 'email_history_page.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/medium_rectangular_ad_widget.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _drawerController;
  late Animation<Offset> _drawerSlide;
  bool _isDrawerOpen = false;
  final AdsService _adsService = AdsService();
  final AppUpdateService _appUpdateService = AppUpdateService();

  @override
  void initState() {
    super.initState();

    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _drawerSlide = Tween<Offset>(
      begin: const Offset(-1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeOutCubic,
    ));

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
    
    // Initialize ads
    _initializeAds();
    
    // Check for app updates from VPS
    _checkForAppUpdates();
  }

  void _initializeAds() async {
    await _adsService.initialize();
    if (mounted) {
      _adsService.loadInterstitialAd();
      _adsService.loadBannerAd();
    }
  }

  void _checkForAppUpdates() async {
    // Add a small delay to ensure the UI is fully loaded
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      await _appUpdateService.checkForVPSUpdate(context);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _drawerController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    if (_drawerController.isDismissed) {
      _drawerController.forward();
    } else {
      _drawerController.reverse();
    }
  }

  void _generateEmail() async {
    final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);
    final emailProvider = Provider.of<EmailProvider>(context, listen: false);
    
    // Show interstitial ad for non-premium users
    if (!premiumProvider.isPremium) {
      _adsService.showInterstitialAd(
        onAdClosed: () {
          _performEmailGeneration(emailProvider);
        },
      );
    } else {
      _performEmailGeneration(emailProvider);
    }
  }

  void _performEmailGeneration(EmailProvider emailProvider) async {
    await emailProvider.generateRandomEmail();
    if (mounted) {
      _showEmailGeneratedSnackBar();
    }
  }

  void _showEmailGeneratedSnackBar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('New email generated successfully!'),
          backgroundColor: const Color(0xFF00D4AA),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _deleteEmail() {
    final emailProvider = Provider.of<EmailProvider>(context, listen: false);
    if (emailProvider.currentEmail != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A2434),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Delete Email', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to delete this email address?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                emailProvider.clearCurrentEmail();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Email deleted successfully!'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }

  void _showQRCode() {
    final emailProvider = Provider.of<EmailProvider>(context, listen: false);
    if (emailProvider.currentEmail != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A2434),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('QR Code', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: QrImageView(
                  data: emailProvider.currentEmail!,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emailProvider.currentEmail!,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF00D4AA))),
            ),
          ],
        ),
      );
    }
  }

  void _showHistoryList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F1C2E),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: EmailHistoryPage(scrollController: scrollController),
        ),
      ),
    );
  }

  void _navigateToInbox() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InboxScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumProvider>(
      builder: (context, premiumProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F1C2E),
          body: Stack(
            children: [
              // Main content
              Scaffold(
                backgroundColor: const Color(0xFF0F1C2E),
                appBar: AppBar(
                  backgroundColor: const Color(0xFF1A2434),
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.menu,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _toggleDrawer,
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4AA),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.email,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'TurboMail',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white70),
                      onPressed: () {
                        context.slideToPage(
                          const PremiumScreen(),
                          direction: SlideDirection.leftToRight,
                          duration: const Duration(milliseconds: 350),
                        );
                      },
                    ),
                  ],
                ),
                body: Consumer<EmailProvider>(
                  builder: (context, emailProvider, child) {
                    return Column(
                      children: [
                        Expanded(
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 0),
                                      _buildEmailDisplay(emailProvider),
                                      const SizedBox(height: 15),
                                      _buildButtonRows(emailProvider),
                                      const SizedBox(height: 15),

                                      if (!premiumProvider.isPremium)
                                      const SizedBox(height: 15),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Sticky banner ad at bottom for non-premium users (only when drawer is closed)
                        if (!premiumProvider.isPremium && _drawerController.value == 0)
                          Container(
                            color: const Color(0xFF0F1C2E),
                            child: const MediumRectangularAdWidget(),
                          ),
                      ],
                    );
                  },
                ),
              ),

              // Smooth animated drawer with outside tap to close
              if (_drawerController.value > 0)
                FadeTransition(
                  opacity: _drawerController,
                  child: GestureDetector(
                    onTap: () => _drawerController.reverse(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              SlideTransition(
                position: _drawerSlide,
                child: FullScreenDrawer(
                  isOpen: _drawerController.value > 0,
                  onClose: () => _drawerController.reverse(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildEmailDisplay(EmailProvider emailProvider) {
    return Container(
      margin: const EdgeInsets.only(left: 0,right: 0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2434),
        //color: const Color(0xFF0D1723),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF00D4AA).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4AA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.mail_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Temporary Email',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (emailProvider.currentEmail != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Email content area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF00D49B), // turquoise green
                  Color(0xFF02B58B), // deep teal
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: emailProvider.currentEmail != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Email Address:',
                        style: TextStyle(
                          color: Color(0xFF1A2434),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 📩 Email Text Container
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F1C2E),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                emailProvider.currentEmail!,
                                style: const TextStyle(
                                  color: Color(0xFF00D4AA),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // 📋 Copy Button Container
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: emailProvider.currentEmail!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: const [
                                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text('Email copied to clipboard!'),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF00D4AA),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00D49B),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF0F1C2E),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.copy,
                                color: Color(0xFF0F1C2E),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Inbox: ${emailProvider.emails.length} messages',
                        style: const TextStyle(
                          color: Color(0xFF1A2434),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  )
                : const Column(
                    children: [
                      Icon(
                        Icons.mail_outline,
                        color: Colors.white38,
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No Active Email',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Generate a new email to get started',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
  Widget _buildButtonRows(EmailProvider emailProvider) {
    return Column(
      children: [
        // Single row with 3 buttons horizontally
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                title: 'Generate Email',
                icon: Icons.refresh,
                onTap: _generateEmail,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                title: 'Delete Email',
                icon: Icons.delete_outline,
                onTap: emailProvider.currentEmail != null ? _deleteEmail : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                title: 'History List',
                icon: Icons.history,
                onTap: _showHistoryList,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final bool isEnabled = onTap != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled 
                ? const Color(0xFF00D4AA).withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isEnabled ? const Color(0xFF00D4AA) : Colors.white38,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}