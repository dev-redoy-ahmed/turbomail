import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/email_provider.dart';
import '../models/email_models.dart';

class EmailListScreen extends StatelessWidget {
  const EmailListScreen({super.key});

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $text'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showEmailOptions(BuildContext context, GeneratedEmail email) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Email'),
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard(context, email.email);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inbox),
              title: const Text('Check Inbox'),
              onTap: () async {
                Navigator.pop(context);
                final emailProvider = Provider.of<EmailProvider>(context, listen: false);
                await emailProvider.getInbox(email.email);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Set as Current'),
              onTap: () {
                Navigator.pop(context);
                final emailProvider = Provider.of<EmailProvider>(context, listen: false);
                emailProvider.setCurrentEmail(email);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Set ${email.email} as current'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),

          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Emails'),
        centerTitle: true,
        actions: [
          Consumer<EmailProvider>(
            builder: (context, emailProvider, child) {
              if (emailProvider.generatedEmails.isEmpty) return const SizedBox();
              
              return PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const ListTile(
                      leading: Icon(Icons.clear_all),
                      title: Text('Clear All'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onTap: () {
                      Future.delayed(Duration.zero, () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear All Emails'),
                            content: const Text('Remove all generated emails from the list?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  emailProvider.clearAll();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('All emails cleared'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                },
                                child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      });
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<EmailProvider>(
        builder: (context, emailProvider, child) {
          if (emailProvider.generatedEmails.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No emails generated yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Go to Generate tab to create your first email',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: emailProvider.generatedEmails.length,
            itemBuilder: (context, index) {
              final email = emailProvider.generatedEmails[index];
              final isCurrent = emailProvider.currentEmail?.email == email.email;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isCurrent ? 4 : 2,
                color: isCurrent ? Colors.blue[50] : null,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: isCurrent ? Colors.blue : Colors.grey[300],
                    child: Icon(
                      isCurrent ? Icons.star : Icons.email,
                      color: isCurrent ? Colors.white : Colors.grey[600],
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          email.email,
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? Colors.blue[800] : null,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Generated: ${email.formattedTimestamp}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await emailProvider.getInbox(email.email);
                              },
                              icon: const Icon(Icons.inbox, size: 16),
                              label: const Text('Check Inbox'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _copyToClipboard(context, email.email),
                            icon: const Icon(Icons.copy, size: 20),
                            tooltip: 'Copy Email',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => _showEmailOptions(context, email),
                ),
              );
            },
          );
        },
      ),
    );
  }
}