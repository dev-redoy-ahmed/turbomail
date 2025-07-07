import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/email_provider.dart';
import '../models/email_models.dart';
import 'package:intl/intl.dart';

class EmailHistoryScreen extends StatefulWidget {
  const EmailHistoryScreen({Key? key}) : super(key: key);

  @override
  State<EmailHistoryScreen> createState() => _EmailHistoryScreenState();
}

class _EmailHistoryScreenState extends State<EmailHistoryScreen> {
  bool _showActiveOnly = false;
  Map<String, dynamic>? _deviceInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    _loadUserEmails();
  }

  Future<void> _loadUserEmails() async {
    final emailProvider = Provider.of<EmailProvider>(context, listen: false);
    await emailProvider.loadUserGeneratedEmails();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final emailProvider = Provider.of<EmailProvider>(context, listen: false);
      final deviceInfo = await emailProvider.getDeviceInfo();
      if (mounted) {
        setState(() {
          _deviceInfo = deviceInfo;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load device info: $e')),
        );
      }
    }
  }



  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadUserEmails();
    await _loadDeviceInfo();
  }

  void _showDeviceInfo() {
    if (_deviceInfo != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Device Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Device ID: ${_deviceInfo!['deviceId'] ?? 'Unknown'}'),
              const SizedBox(height: 8),
              const Text('Device Info:', style: TextStyle(fontWeight: FontWeight.bold)),
              if (_deviceInfo!['deviceInfo'] != null)
                ..._deviceInfo!['deviceInfo'].entries.map<Widget>((entry) {
                  return Text('${entry.key}: ${entry.value}');
                }).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _copyToClipboard(_deviceInfo!['deviceId']?.toString() ?? 'Unknown');
                Navigator.of(context).pop();
              },
              child: const Text('Copy Device ID'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _toggleFilter() {
    setState(() {
      _showActiveOnly = !_showActiveOnly;
    });
    _loadUserEmails();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard: $text'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDeleteConfirmation(GeneratedEmail email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Email'),
          content: Text('Are you sure you want to delete ${email.email}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteEmail(email);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEmail(GeneratedEmail email) async {
    final provider = Provider.of<EmailProvider>(context, listen: false);
    await provider.deleteGeneratedEmail(email);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email ${email.email} deleted'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _switchToEmail(GeneratedEmail email) async {
    final provider = Provider.of<EmailProvider>(context, listen: false);
    await provider.switchToEmail(email);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to ${email.email}'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TempMail Pro'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0D1B2A),
              ),
            )
          : Consumer<EmailProvider>(builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF0D1B2A),
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Error: ${provider.error}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _refreshData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D1B2A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final emails = provider.generatedEmails;

        if (emails.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B2A).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    size: 64,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _showActiveOnly 
                      ? 'No active emails found'
                      : 'No emails generated yet',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Color(0xFF0D1B2A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate some emails to see them here',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D1B2A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Generate Email'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Filter toggle
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list,
                    color: Color(0xFF0D1B2A),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Show active only',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _showActiveOnly,
                    onChanged: (value) => _toggleFilter(),
                    activeColor: const Color(0xFF0D1B2A),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1B2A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: _refreshData,
                      icon: const Icon(
                        Icons.refresh,
                        color: Color(0xFF0D1B2A),
                      ),
                      tooltip: 'Refresh',
                    ),
                  ),
                ],
              ),
            ),
            
            // Email list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                color: const Color(0xFF0D1B2A),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: emails.length,
                  itemBuilder: (context, index) {
                    final email = emails[index];
                    final isCurrentEmail = provider.currentEmail?.id == email.id;
                    final isExpired = email.expiresAt?.isBefore(DateTime.now()) ?? false;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isCurrentEmail 
                            ? Border.all(color: const Color(0xFF0D1B2A), width: 2)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isCurrentEmail
                                    ? const Color(0xFF0D1B2A)
                                    : isExpired 
                                        ? Colors.red.withOpacity(0.1)
                                        : email.isActive
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isCurrentEmail 
                                    ? Icons.star 
                                    : email.isActive 
                                        ? Icons.check 
                                        : Icons.email,
                                color: isCurrentEmail
                                    ? Colors.white
                                    : isExpired 
                                        ? Colors.red
                                        : email.isActive
                                            ? Colors.green
                                            : Colors.grey,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    email.email,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isExpired ? Colors.grey[600] : const Color(0xFF0D1B2A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Type: ${email.type}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (email.createdAt != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(email.createdAt!)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                  if (email.expiresAt != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Expires: ${DateFormat('MMM dd, yyyy HH:mm').format(email.expiresAt!)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isExpired ? Colors.red : Colors.grey[500],
                                        fontWeight: isExpired ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                  if (isCurrentEmail)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0D1B2A),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'CURRENT',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D1B2A).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Color(0xFF0D1B2A),
                                ),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'copy':
                                      _copyToClipboard(email.email);
                                      break;
                                    case 'switch':
                                      _switchToEmail(email);
                                      break;
                                    case 'delete':
                                      _showDeleteConfirmation(email);
                                      break;
                                  }
                                },
                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem(
                                    value: 'copy',
                                    child: ListTile(
                                      leading: Icon(Icons.copy, color: Color(0xFF0D1B2A)),
                                      title: Text('Copy Email'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  if (!isCurrentEmail)
                                    const PopupMenuItem(
                                      value: 'switch',
                                      child: ListTile(
                                        leading: Icon(Icons.swap_horiz, color: Color(0xFF0D1B2A)),
                                        title: Text('Switch to This'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(Icons.delete, color: Colors.red),
                                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}