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
        title: const Text('Email History'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDeviceInfo,
            tooltip: 'Device Info',
          ),
          IconButton(
             icon: Icon(_showActiveOnly ? Icons.visibility : Icons.visibility_off),
             onPressed: () {
               setState(() {
                 _showActiveOnly = !_showActiveOnly;
               });
             },
             tooltip: _showActiveOnly ? 'Show All' : 'Show Active Only',
           ),
           IconButton(
             icon: const Icon(Icons.refresh),
             onPressed: _refreshData,
             tooltip: 'Refresh',
           ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<EmailProvider>(builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (provider.error != null) {
          return Center(
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
                  'Error: ${provider.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshData,
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
                Icon(
                  Icons.email_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _showActiveOnly 
                      ? 'No active emails found'
                      : 'No emails generated yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate some emails to see them here',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
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
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Show active only',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Switch(
                    value: _showActiveOnly,
                    onChanged: (value) => _toggleFilter(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            // Email list
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                child: ListView.builder(
                  itemCount: emails.length,
                  itemBuilder: (context, index) {
                    final email = emails[index];
                    final isCurrentEmail = provider.currentEmail?.id == email.id;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      elevation: isCurrentEmail ? 4 : 1,
                      color: isCurrentEmail 
                          ? Colors.blue[50] 
                          : email.isActive 
                              ? Colors.green[50] 
                              : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCurrentEmail 
                              ? Colors.blue 
                              : email.isActive 
                                  ? Colors.green 
                                  : Colors.grey,
                          child: Icon(
                            isCurrentEmail 
                                ? Icons.star 
                                : email.isActive 
                                    ? Icons.check 
                                    : Icons.email,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          email.email,
                          style: TextStyle(
                            fontWeight: isCurrentEmail 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: ${email.type}'),
                            if (email.createdAt != null)
                              Text(
                                'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(email.createdAt!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            if (email.expiresAt != null)
                              Text(
                                'Expires: ${DateFormat('MMM dd, yyyy HH:mm').format(email.expiresAt!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: email.expiresAt!.isBefore(DateTime.now()) 
                                      ? Colors.red[600] 
                                      : Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
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
                                leading: Icon(Icons.copy),
                                title: Text('Copy Email'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            if (!isCurrentEmail)
                              const PopupMenuItem(
                                value: 'switch',
                                child: ListTile(
                                  leading: Icon(Icons.swap_horiz),
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
                        onTap: () => _copyToClipboard(email.email),
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