import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/email_provider.dart';
import '../providers/premium_provider.dart';
import '../services/api_service.dart';
import '../services/device_service.dart';
import '../services/ads_service.dart';
import '../utils/page_transitions.dart';
import '../widgets/adaptive_banner_ad_widget.dart';
import 'inbox_screen.dart';

class EmailHistoryPage extends StatefulWidget {
  final ScrollController? scrollController;
  
  const EmailHistoryPage({super.key, this.scrollController});

  @override
  State<EmailHistoryPage> createState() => _EmailHistoryPageState();
}

class _EmailHistoryPageState extends State<EmailHistoryPage> {
  final ApiService _apiService = ApiService();
  List<HistoryEmailModel> _emails = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePages = false;
  String _deviceId = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    _loadEmailHistory();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfo = await DeviceService.getDeviceInfo();
      final deviceId = deviceInfo['deviceId']!;
      print('📱 Email History - Device ID: $deviceId');
      setState(() {
        _deviceId = deviceId;
      });
    } catch (e) {
      print('❌ Error loading device info: $e');
    }
  }

  Future<void> _loadEmailHistory({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _emails.clear();
        _isLoading = true;
        _error = null;
      });
    }

    try {
      print('📧 Loading email history - Page: $_currentPage, Refresh: $refresh');
      final response = await _apiService.getEmailHistory(
        page: _currentPage,
        limit: 20,
      );
      print('✅ Email history loaded - Count: ${response.emails.length}, Total Pages: ${response.pagination.pages}');

      setState(() {
        if (refresh) {
          _emails = response.emails;
        } else {
          _emails.addAll(response.emails);
        }
        _hasMorePages = _currentPage < response.pagination.pages;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      print('❌ Error loading email history: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreEmails() async {
    if (_hasMorePages && !_isLoading) {
      setState(() {
        _currentPage++;
      });
      await _loadEmailHistory();
    }
  }

  Future<void> _toggleStar(HistoryEmailModel email) async {
    try {
      await _apiService.toggleEmailStar(email.email, !email.isStarred);
      
      setState(() {
        final index = _emails.indexWhere((e) => e.id == email.id);
        if (index != -1) {
          _emails[index] = HistoryEmailModel(
            id: email.id,
            email: email.email,
            deviceId: email.deviceId,
            type: email.type,
            isStarred: !email.isStarred,
            createdAt: email.createdAt,
            lastUsed: email.lastUsed,
            username: email.username,
            domain: email.domain,
          );
          
          // Re-sort to move starred emails to top
          _emails.sort((a, b) {
            if (a.isStarred && !b.isStarred) return -1;
            if (!a.isStarred && b.isStarred) return 1;
            return b.createdAt.compareTo(a.createdAt);
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(email.isStarred ? 'Removed from favorites' : 'Added to favorites'),
          backgroundColor: email.isStarred ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorite: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteEmail(HistoryEmailModel email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2434),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Email', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${email.email}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteEmailFromHistory(email.email);
        setState(() {
          _emails.removeWhere((e) => e.id == email.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email deleted from history'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _switchToEmail(HistoryEmailModel email) async {
    final premiumProvider = Provider.of<PremiumProvider>(context, listen: false);
    
    try {
      // Check if user is premium
      if (!premiumProvider.isPremium) {
        // Show interstitial ad for non-premium users
        final adsService = AdsService();
        
        adsService.showInterstitialAd(
          onAdClosed: () {
            // Proceed with email switch after ad is closed
            _performEmailSwitch(email.email);
          },
        );
        
        // Check if ad is available
        if (!adsService.isInterstitialAdLoaded) {
          // If no ad available, proceed directly
          _performEmailSwitch(email.email);
        }
      } else {
        // Premium user, switch directly
        _performEmailSwitch(email.email);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to switch to email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _performEmailSwitch(String email) {
    try {
      final emailProvider = Provider.of<EmailProvider>(context, listen: false);
      
      // Set the current email in the provider
      emailProvider.setCurrentEmail(email);
      
      // Navigate to inbox screen with slide transition
      // This will automatically replace the current route including the modal
      context.slideReplacePage(
        const InboxScreen(),
        direction: SlideDirection.rightToLeft,
        duration: const Duration(milliseconds: 400),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to switch to email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121A2D), // Background color of sheet
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: const Border(
          top: BorderSide(
            color: Color(0xFF00D4AA), // ✅ Top border color
            width: 3.0,               // ✅ Border thickness
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ✅ Drag handle
          Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.only(top: 10, bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // ✅ Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4AA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Email History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF00D4AA)),
                  onPressed: () => _loadEmailHistory(refresh: true),
                ),
              ],
            ),
          ),

          // ✅ Content
          Expanded(
            child: _isLoading && _emails.isEmpty
                ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
              ),
            )
                : _error != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading history',
                    style: TextStyle(
                      color: Colors.red[300],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _loadEmailHistory(refresh: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4AA),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
                : _emails.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No email history',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate some emails to see them here',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
                : Column(
              children: [
                // ✅ Device info header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2434),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00D4AA).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Device Information',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Device ID: ${_deviceId.isNotEmpty ? _deviceId.substring(0, 8) : 'Loading'}...',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        'Total Emails: ${_emails.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // ✅ Email list
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent &&
                          _hasMorePages &&
                          !_isLoading) {
                        _loadMoreEmails();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _emails.length + (_hasMorePages ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _emails.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF00D4AA),
                                ),
                              ),
                            ),
                          );
                        }

                        final email = _emails[index];
                        return _buildEmailCard(email);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ✅ Banner ad at bottom
          Consumer<PremiumProvider>(
            builder: (context, premiumProvider, child) {
              if (!premiumProvider.isPremium) {
                return const AdaptiveBannerAdWidget();
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }


  Widget _buildEmailCard(HistoryEmailModel email) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2434),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: email.isStarred
              ? const Color(0xFFFFD700).withOpacity(0.5)
              : const Color(0xFF00D4AA).withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: email.type == 'custom'
              ? const Color(0xFF00D4AA)
              : const Color(0xFF00D49B),
          child: Icon(
            email.type == 'custom' ? Icons.person : Icons.shuffle,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                email.email,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (email.isStarred)
              const Icon(
                Icons.star,
                color: Color(0xFFFFD700),
                size: 20,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Type: ${email.type.toUpperCase()}',
              style: TextStyle(
                color: email.type == 'custom'
                    ? const Color(0xFF00D4AA)
                    : const Color(0xFF00D49B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Created: ${_formatDate(email.createdAt)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            Text(
              'Last used: ${_formatDate(email.lastUsed)}',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          color: const Color(0xFF1A2434),
          onSelected: (value) {
            switch (value) {
              case 'switch':
                _switchToEmail(email);
                break;
              case 'star':
                _toggleStar(email);
                break;
              case 'delete':
                _deleteEmail(email);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'switch',
              child: Row(
                children: [
                  Icon(Icons.switch_account, color: Colors.white70),
                  SizedBox(width: 8),
                  Text('Switch to this email', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'star',
              child: Row(
                children: [
                  Icon(
                    email.isStarred ? Icons.star_border : Icons.star,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    email.isStarred ? 'Remove from favorites' : 'Add to favorites',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _switchToEmail(email),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}