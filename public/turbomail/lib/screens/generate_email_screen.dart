import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../providers/email_provider.dart';

class GenerateEmailScreen extends StatefulWidget {
  const GenerateEmailScreen({super.key});

  @override
  State<GenerateEmailScreen> createState() => _GenerateEmailScreenState();
}

class _GenerateEmailScreenState extends State<GenerateEmailScreen> {
  final _usernameController = TextEditingController();
  String _selectedDomain = 'oplex.online';
  bool _isManualMode = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $text'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Email'),
        centerTitle: true,
      ),
      body: Consumer<EmailProvider>(
        builder: (context, emailProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mode Toggle
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Email Generation Mode',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ToggleButtons(
                          isSelected: [!_isManualMode, _isManualMode],
                          onPressed: (index) {
                            setState(() {
                              _isManualMode = index == 1;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Random'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Manual'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Manual Mode Form
                if (_isManualMode) ...
                [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Custom Email Configuration',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              hintText: 'Enter username (e.g., john)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedDomain,
                            decoration: const InputDecoration(
                              labelText: 'Domain',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.domain),
                            ),
                            items: emailProvider.getAvailableDomains()
                                .map((domain) => DropdownMenuItem(
                                      value: domain,
                                      child: Text(domain),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedDomain = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.preview, color: Colors.grey),
                                const SizedBox(width: 8),
                                const Text('Preview: '),
                                Text(
                                  _usernameController.text.isEmpty
                                      ? 'username@$_selectedDomain'
                                      : '${_usernameController.text}@$_selectedDomain',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Generate Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: emailProvider.isLoading
                        ? null
                        : () async {
                            if (_isManualMode) {
                              if (_usernameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a username'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              await emailProvider.generateManualEmail(
                                _usernameController.text.trim(),
                                _selectedDomain,
                              );
                            } else {
                              await emailProvider.generateRandomEmail();
                            }
                          },
                    icon: emailProvider.isLoading
                        ? const SpinKitThreeBounce(
                            color: Colors.white,
                            size: 20,
                          )
                        : const Icon(Icons.email),
                    label: Text(
                      emailProvider.isLoading
                          ? 'Generating...'
                          : _isManualMode
                              ? 'Generate Custom Email'
                              : 'Generate Random Email',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Error Message
                if (emailProvider.errorMessage != null)
                  Card(
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

                // Current Generated Email
                if (emailProvider.currentEmail != null) ...
                [
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 8),
                              const Text(
                                'Email Generated Successfully!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Email Address:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        emailProvider.currentEmail!.email,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _copyToClipboard(
                                    emailProvider.currentEmail!.email,
                                  ),
                                  icon: const Icon(Icons.copy),
                                  tooltip: 'Copy Email',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await emailProvider.getInbox(
                                      emailProvider.currentEmail!.email,
                                    );
                                  },
                                  icon: const Icon(Icons.inbox),
                                  label: const Text('Check Inbox'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Instructions
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            const Text(
                              'How to use TurboMail',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '1. Generate a temporary email address\n'
                          '2. Use it for registrations or testing\n'
                          '3. Check inbox for received emails\n'
                          '4. Delete emails when done',
                          style: TextStyle(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}