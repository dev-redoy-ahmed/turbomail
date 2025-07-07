import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/email_provider.dart';
import '../models/email_models.dart';
import 'email_detail_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final TextEditingController _emailController = TextEditingController();
  Timer? _autoRefreshTimer;
  bool _autoRefreshEnabled = true;

  @override
  void dispose() {
    _emailController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    if (_autoRefreshEnabled) {
      _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        final emailProvider = Provider.of<EmailProvider>(context, listen: false);
        if (emailProvider.currentInbox != null && mounted) {
          emailProvider.refreshInbox();
        }
      });
    }
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
  }

  void _toggleAutoRefresh() {
    setState(() {
      _autoRefreshEnabled = !_autoRefreshEnabled;
      if (_autoRefreshEnabled) {
        _startAutoRefresh();
      } else {
        _stopAutoRefresh();
      }
    });
  }

  void _showDeleteConfirmation(BuildContext context, String email, {int? index}) {
    final isDeleteAll = index == null;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDeleteAll ? 'Delete All Messages' : 'Delete Message'),
        content: Text(
          isDeleteAll
              ? 'Delete all messages from $email?\n\nThis action cannot be undone.'
              : 'Delete this message?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final emailProvider = Provider.of<EmailProvider>(context, listen: false);
              
              bool success;
              if (isDeleteAll) {
                success = await emailProvider.deleteAllMessages(email);
              } else {
                success = await emailProvider.deleteSpecificMessage(email, index!);
              }
              
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isDeleteAll ? 'All messages deleted successfully' : 'Message deleted successfully',
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        emailProvider.errorMessage ?? 'Failed to delete. Please try again.',
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'Retry',
                        textColor: Colors.white,
                        onPressed: () {
                          // Retry the delete operation
                          if (isDeleteAll) {
                            emailProvider.deleteAllMessages(email);
                          } else {
                            emailProvider.deleteSpecificMessage(email, index!);
                          }
                        },
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Check Inbox',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'Enter email to check inbox',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<EmailProvider>(
                  builder: (context, emailProvider, child) {
                    return IconButton(
                      onPressed: emailProvider.isLoading
                          ? null
                          : () async {
                              if (_emailController.text.trim().isNotEmpty) {
                                await emailProvider.getInbox(_emailController.text.trim());
                                _startAutoRefresh(); // Start auto-refresh after loading inbox
                              }
                            },
                      icon: emailProvider.isLoading
                          ? const SpinKitThreeBounce(
                              color: Colors.blue,
                              size: 20,
                            )
                          : const Icon(Icons.search),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Consumer<EmailProvider>(
              builder: (context, emailProvider, child) {
                if (emailProvider.generatedEmails.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Select:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: emailProvider.generatedEmails.map((email) {
                          return ActionChip(
                            label: Text(
                              email.email,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () async {
                              _emailController.text = email.email;
                              await emailProvider.getInbox(email.email);
                              _startAutoRefresh(); // Start auto-refresh after loading inbox
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInboxContent(EmailProvider emailProvider) {
    if (emailProvider.currentInbox == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No inbox selected',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter an email address to check its inbox',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    final inbox = emailProvider.currentInbox!;
    
    if (inbox.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No messages',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Inbox for ${inbox.email} is empty',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => emailProvider.refreshInbox(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Inbox Header
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inbox.email,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${inbox.count} message${inbox.count != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _toggleAutoRefresh,
                  icon: Icon(
                    _autoRefreshEnabled ? Icons.pause : Icons.play_arrow,
                    color: _autoRefreshEnabled ? Colors.green : Colors.grey,
                  ),
                  tooltip: _autoRefreshEnabled ? 'Stop Auto-Refresh' : 'Start Auto-Refresh',
                ),
                IconButton(
                  onPressed: () {
                    emailProvider.refreshInbox();
                    if (_autoRefreshEnabled) {
                      _startAutoRefresh(); // Restart timer
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Manual Refresh',
                ),
                if (inbox.count > 0)
                  IconButton(
                    onPressed: () => _showDeleteConfirmation(context, inbox.email),
                    icon: const Icon(Icons.delete_sweep, color: Colors.red),
                    tooltip: 'Delete All',
                  ),
              ],
            ),
          ),
        ),
        
        // Messages List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: inbox.messages.length,
            itemBuilder: (context, index) {
              final message = inbox.messages[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      message.from.isNotEmpty ? message.from[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    message.subject.isNotEmpty ? message.subject : 'No Subject',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'From: ${message.from}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message.shortContent,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.formattedDate,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const ListTile(
                          leading: Icon(Icons.visibility),
                          title: Text('View'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onTap: () {
                          Future.delayed(Duration.zero, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EmailDetailScreen(
                                  message: message,
                                  emailAddress: inbox.email,
                                  messageIndex: index,
                                ),
                              ),
                            );
                          });
                        },
                      ),
                      PopupMenuItem(
                        child: const ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onTap: () {
                          Future.delayed(Duration.zero, () {
                            _showDeleteConfirmation(context, inbox.email, index: index);
                          });
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmailDetailScreen(
                          message: message,
                          emailAddress: inbox.email,
                          messageIndex: index,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        centerTitle: true,
      ),
      body: Consumer<EmailProvider>(
        builder: (context, emailProvider, child) {
          return Column(
            children: [
              _buildEmailInput(),
              
              // Error Message
              if (emailProvider.errorMessage != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  child: Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              emailProvider.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          IconButton(
                            onPressed: emailProvider.clearError,
                            icon: const Icon(Icons.close, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Loading or Inbox Content
              Expanded(
                child: emailProvider.isLoading
                    ? const Center(
                        child: SpinKitThreeBounce(
                          color: Colors.blue,
                          size: 30,
                        ),
                      )
                    : _buildInboxContent(emailProvider),
              ),
            ],
          );
        },
      ),
    );
  }
}