import 'package:flutter/material.dart';
import '../utils/page_transitions.dart';

class CustomDrawer extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;

  const CustomDrawer({
    super.key,
    required this.isOpen,
    required this.onClose,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize slide animation with smoother curve and longer duration
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic, // Smoother curve
    ));

    // Initialize fade animation for overlay
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(CustomDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _slideController.forward();
        _fadeController.forward();
      } else {
        _slideController.reverse();
        _fadeController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen && _slideController.isDismissed) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Dark overlay
        FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
            ),
          ),
        ),

        // Drawer content
        SlideTransition(
          position: _slideAnimation,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF1A2434),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Top section with centered app icon and close button
                Container(
                  padding: const EdgeInsets.only(top: 60, bottom: 30),
                  child: Stack(
                    children: [
                      // Close button positioned at top right
                      Positioned(
                        top: 0,
                        right: 20,
                        child: IconButton(
                          onPressed: widget.onClose,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
                      ),
                      // Centered app icon
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4AA),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.email,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                  // Menu items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Premium section
                        _buildMenuItem(
                          icon: Icons.workspace_premium,
                          title: 'Premium',
                          hasSwitch: false,
                          showBadge: true,
                          onTap: () {
                            widget.onClose();
                          },
                        ),

                        const SizedBox(height: 12),

                        // Custom Email Address
                        _buildMenuItem(
                          icon: Icons.alternate_email,
                          title: 'Custom Email Address',
                          hasSwitch: false,
                          onTap: () {
                            widget.onClose();
                          },
                        ),

                        const SizedBox(height: 12),

                        // Private domains
                        _buildMenuItem(
                          icon: Icons.domain,
                          title: 'Private domains',
                          hasSwitch: false,
                          onTap: () {
                            widget.onClose();
                          },
                        ),

                        const SizedBox(height: 12),

                        // Web Premium
                        _buildMenuItem(
                          icon: Icons.web,
                          title: 'Web Premium',
                          hasSwitch: false,
                          onTap: () {
                            widget.onClose();
                          },
                        ),

                        const SizedBox(height: 12),

                        // Change language
                        _buildMenuItem(
                          icon: Icons.language,
                          title: 'Change language',
                          hasSwitch: false,
                          onTap: () {
                            widget.onClose();
                          },
                        ),

                        const SizedBox(height: 12),

                        // Dark mode
                        _buildMenuItem(
                          icon: Icons.dark_mode,
                          title: 'Dark mode',
                          hasSwitch: true,
                          switchValue: true,
                          onSwitchChanged: (value) {
                            // Handle dark mode toggle
                          },
                        ),

                        const SizedBox(height: 12),

                        // Animations
                        _buildMenuItem(
                          icon: Icons.animation,
                          title: 'Animations',
                          hasSwitch: true,
                          switchValue: true,
                          onSwitchChanged: (value) {
                            // Handle animations toggle
                          },
                        ),

                        const SizedBox(height: 12),

                        // Notifications
                        _buildMenuItem(
                          icon: Icons.notifications,
                          title: 'Notifications',
                          hasSwitch: true,
                          switchValue: true,
                          onSwitchChanged: (value) {
                            // Handle notifications toggle
                          },
                        ),

                        const SizedBox(height: 12),

                        // Autofill
                        _buildMenuItem(
                          icon: Icons.auto_fix_high,
                          title: 'Autofill',
                          hasSwitch: true,
                          switchValue: false,
                          onSwitchChanged: (value) {
                            // Handle autofill toggle
                          },
                        ),

                        const SizedBox(height: 12),

                        // Help Center
                        _buildMenuItem(
                          icon: Icons.help_center,
                          title: 'Help Center',
                          hasSwitch: false,
                          onTap: () {
                            widget.onClose();
                          },
                        ),

                        const SizedBox(height: 12),

                        // Rate us
                        _buildMenuItem(
                          icon: Icons.star_rate,
                          title: 'Rate us',
                          hasSwitch: false,
                          onTap: () {
                            widget.onClose();
                          },
                        ),

                        const SizedBox(height: 30),

                      ],
                    ),
                  ),

                // Premium banner
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB347), Color(0xFFFF8C42)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.rocket_launch,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Want more?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Premium',
                          style: TextStyle(
                            color: Color(0xFFFF8C42),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Terms',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Text(
                            '•',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Privacy',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'App version 4.02',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    bool hasSwitch = false,
    bool switchValue = false,
    bool showBadge = false,
    VoidCallback? onTap,
    ValueChanged<bool>? onSwitchChanged,
  }) {
    return InkWell(
      onTap: hasSwitch ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white70,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (showBadge)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'TRY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (hasSwitch)
              Switch(
                value: switchValue,
                onChanged: onSwitchChanged,
                activeColor: const Color(0xFF00D4AA),
                inactiveThumbColor: Colors.white54,
                inactiveTrackColor: Colors.white24,
              ),
          ],
        ),
      ),
    );
  }
}