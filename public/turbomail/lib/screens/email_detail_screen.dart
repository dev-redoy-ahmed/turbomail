import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/email_provider.dart';
import '../models/email_models.dart';

class EmailDetailScreen extends StatelessWidget {
  final EmailMessage message;
  final String emailAddress;
  final int messageIndex;

  const EmailDetailScreen({
    super.key,
    required this.message,
    required this.emailAddress,
    required this.messageIndex,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $label'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }



  Widget _buildInfoRow(String label, String value, {VoidCallback? onCopy}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
          if (onCopy != null)
            IconButton(
              onPressed: onCopy,
              icon: const Icon(Icons.copy, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Copy',
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsList(BuildContext context) {
    if (message.attachments.isEmpty) {
      return const SizedBox();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_file, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Attachments (${message.attachments.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...message.attachments.map((attachment) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFileIcon(attachment),
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        attachment,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _copyToClipboard(
                        context,
                        attachment,
                        'attachment name',
                      ),
                      icon: const Icon(Icons.copy, size: 16),
                      tooltip: 'Copy filename',
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'zip':
      case 'rar':
        return Icons.archive;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Details'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Copy Subject'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () => _copyToClipboard(
                  context,
                  message.subject,
                  'subject',
                ),
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Copy Content'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () => _copyToClipboard(
                  context,
                  message.content,
                  'message content',
                ),
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Message', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () => _showDeleteConfirmation(context),
              ),

            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.subject.isNotEmpty ? message.subject : 'No Subject',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'From',
                      message.from,
                      onCopy: () => _copyToClipboard(context, message.from, 'sender'),
                    ),
                    _buildInfoRow(
                      'To',
                      emailAddress,
                      onCopy: () => _copyToClipboard(context, emailAddress, 'recipient'),
                    ),
                    _buildInfoRow('Date', message.formattedDate),
                    if (message.timestamp != null)
                      _buildInfoRow('Time', message.timestamp.toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Email Body
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.message, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Message',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => _copyToClipboard(
                            context,
                            message.content,
                            'message content',
                          ),
                          icon: const Icon(Icons.copy, size: 20),
                          tooltip: 'Copy message',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: SelectableText(
                        message.content.isNotEmpty ? message.content : 'No message content',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Attachments
            _buildAttachmentsList(context),
            const SizedBox(height: 16),

            // Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final emailProvider = Provider.of<EmailProvider>(context, listen: false);
                        await emailProvider.refreshInbox();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Inbox refreshed'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Inbox'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 48),
                      ),
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

  // Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Message'),
          content: const Text(
            'Are you sure you want to permanently delete this message from Redis? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteMessage(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Delete the message
  Future<void> _deleteMessage(BuildContext context) async {
    final emailProvider = Provider.of<EmailProvider>(context, listen: false);
    
    // Find the index of this message in the current inbox
    final currentInbox = emailProvider.currentInbox;
    if (currentInbox == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No inbox loaded'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    final messageIndex = currentInbox.messages.indexWhere(
      (msg) => msg.id == message.id && 
               msg.timestamp == message.timestamp &&
               msg.subject == message.subject,
    );
    
    if (messageIndex == -1) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Message not found in inbox'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // Show loading indicator
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deleting message...'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    
    // Delete the message
    final success = await emailProvider.deleteMessage(currentInbox.email, messageIndex);
    
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message deleted permanently from Redis'),
            backgroundColor: Colors.green,
          ),
        );
        // Go back to inbox
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete message: ${emailProvider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}