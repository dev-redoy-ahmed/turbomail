import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/premium_provider.dart';
import '../services/in_app_purchase_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  String? selectedPlan;

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumProvider>(
      builder: (context, premiumProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F1C2E),
          appBar: AppBar(
            title: const Text(
              'Premium',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: const Color(0xFF1A2434),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: premiumProvider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00D4AA),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Premium Header
                      _buildPremiumHeader(premiumProvider),
                      const SizedBox(height: 24),

                      // Features Section
                      _buildFeaturesSection(),
                      const SizedBox(height: 24),

                      // Pricing Plans
                      _buildPricingSection(premiumProvider),
                      const SizedBox(height: 32),

                      // Action Buttons
                      _buildActionButtons(context, premiumProvider),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildPremiumHeader(PremiumProvider premiumProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: premiumProvider.isPremium 
              ? [const Color(0xFF00D4AA), const Color(0xFF1DB584)]
              : [const Color(0xFF00D4AA), const Color(0xFF1DB584)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4AA).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              premiumProvider.isPremium ? Icons.verified : Icons.star,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            premiumProvider.isPremium ? 'Premium Active' : 'TurboMail Premium',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            premiumProvider.isPremium 
                ? 'You are enjoying all premium features'
                : 'Unlock advanced features and enhanced experience',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          if (premiumProvider.isPremium && premiumProvider.activePlan != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Current Plan: ${premiumProvider.getPlanDisplayName(premiumProvider.activePlan)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Premium Features',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          icon: Icons.email_outlined,
          title: 'Unlimited Emails',
          description: 'Create unlimited temporary email addresses',
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.schedule,
          title: 'Extended Duration',
          description: 'Keep emails active for up to 30 days',
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.security,
          title: 'Enhanced Security',
          description: 'Advanced encryption and privacy protection',
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.support_agent,
          title: 'Priority Support',
          description: '24/7 premium customer support',
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.block,
          title: 'Enhanced Experience',
          description: 'Enjoy TurboMail with premium features and priority support',
        ),
      ],
    );
  }

  Widget _buildPricingSection(PremiumProvider premiumProvider) {
    if (premiumProvider.isPremium) {
      return Container(
        padding: const EdgeInsets.all(20),
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
            const Icon(
              Icons.check_circle,
              color: Color(0xFF00D4AA),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'You\'re all set!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enjoy all premium features',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSimplePricingCard(
          productId: InAppPurchaseService.monthlyProductId,
          title: 'Monthly Premium',
          price: _getProductPrice(InAppPurchaseService.monthlyProductId, '৳99'),
          period: '/month',
          icon: Icons.schedule,
          label: 'Basic',
          premiumProvider: premiumProvider,
        ),
        const SizedBox(height: 16),
        _buildSimplePricingCard(
          productId: InAppPurchaseService.threeMonthProductId,
          title: '3 Months Premium',
          price: _getProductPrice(InAppPurchaseService.threeMonthProductId, '৳249'),
          period: '/3 months',
          icon: Icons.trending_up,
          label: 'Popular',
          premiumProvider: premiumProvider,
        ),
        const SizedBox(height: 16),
        _buildSimplePricingCard(
          productId: InAppPurchaseService.sixMonthProductId,
          title: '6 Months Premium',
          price: _getProductPrice(InAppPurchaseService.sixMonthProductId, '৳449'),
          period: '/6 months',
          icon: Icons.star,
          label: 'Best Value',
          premiumProvider: premiumProvider,
        ),
        const SizedBox(height: 16),
        _buildSimplePricingCard(
          productId: InAppPurchaseService.yearlyProductId,
          title: 'Yearly Premium',
          price: _getProductPrice(InAppPurchaseService.yearlyProductId, '৳799'),
          period: '/year',
          icon: Icons.workspace_premium,
          label: 'Pro',
          premiumProvider: premiumProvider,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, PremiumProvider premiumProvider) {
    if (premiumProvider.isPremium) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => premiumProvider.restorePurchases(),
              icon: const Icon(Icons.restore),
              label: const Text(
                'Restore Purchases',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4AA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (selectedPlan != null) ...[
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: premiumProvider.purchaseService.purchasePending
                  ? null
                  : () => _purchaseSelectedPlan(premiumProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4AA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: premiumProvider.purchaseService.purchasePending
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Processing...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Subscribe Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () => premiumProvider.restorePurchases(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00D4AA),
              side: const BorderSide(color: Color(0xFF00D4AA)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Restore Purchases',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimplePricingCard({
    required String productId,
    required String title,
    required String price,
    required String period,
    required IconData icon,
    required String label,
    required PremiumProvider premiumProvider,
  }) {
    final isSelected = selectedPlan == productId;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlan = productId;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2434),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF00D4AA)
                : const Color(0xFF00D4AA).withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Left side - Title and Price
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00D4AA),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        period,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Right side - Icon and Label
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: const Color(0xFF00D4AA),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF00D4AA),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2434),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00D4AA).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF00D4AA),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _purchaseSelectedPlan(PremiumProvider premiumProvider) async {
    if (selectedPlan == null) return;
    
    try {
      await premiumProvider.purchasePlan(selectedPlan!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getProductPrice(String productId, String fallbackPrice) {
    final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);
    final product = premiumProvider.purchaseService.getProductById(productId);
    
    if (product != null) {
      // Return the actual price from Play Store
      return product.price;
    }
    
    // Return fallback price if product not found (for testing/development)
    return fallbackPrice;
  }
}