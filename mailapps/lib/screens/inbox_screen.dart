import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../models/email_model.dart';
import '../providers/email_provider.dart';
import '../providers/premium_provider.dart';
import '../utils/page_transitions.dart';
import '../widgets/medium_rectangular_ad_widget.dart';
import 'email_detail_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final emailProvider = context.read<EmailProvider>();
      if (emailProvider.currentEmail != null) {
        emailProvider.refreshInbox();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumProvider>(
      builder: (context, premiumProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F1C2E),
          body: Column(
            children: [
              // Top section with refresh button and active email on the right
              _buildTopSection(),

              // Main scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Consumer<EmailProvider>(
                    builder: (context, emailProvider, child) {
                      if (emailProvider.currentEmail == null) {
                        return _buildNoEmailStateWithConstraints(emailProvider, premiumProvider.isPremium);
                      }

                      if (emailProvider.emails.isEmpty && !emailProvider.isLoading) {
                        return _buildEmptyInboxStateWithConstraints(emailProvider, premiumProvider.isPremium);
                      }

                      return _buildScrollableEmailList(emailProvider, premiumProvider.isPremium);
                    },
                  ),
                ),
              ),
              
              // Sticky medium rectangular ad at bottom for non-premium users
              if (!premiumProvider.isPremium)
                Container(
                  color: const Color(0xFF0F1C2E),
                  child: const MediumRectangularAdWidget(),
                ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildTopSection() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 8,
        bottom: 16,
      ),
      child: Row(
        children: [
          // Left side - Inbox title
          const Text(
            'Inbox',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const Spacer(),

          // Right side - Active email and refresh button container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2434),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Active email display
                Consumer<EmailProvider>(
                  builder: (context, emailProvider, child) {
                    if (emailProvider.currentEmail == null) {
                      return const Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: Colors.white38,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'No email available',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    }
                    
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4AA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.email,
                            color: Color(0xFF00D4AA),
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Active Email',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                               emailProvider.currentEmail!,
                               style: const TextStyle(
                                 color: Colors.white,
                                 fontSize: 10,
                                 fontWeight: FontWeight.bold,
                               ),
                               overflow: TextOverflow.ellipsis,
                             ),
                           ],
                         ),
                       ],
                     );
                   },
                 ),
                 
                 const SizedBox(width: 12),
                 
                 // Refresh button
                 Consumer<EmailProvider>(
                   builder: (context, emailProvider, child) {
                     return IconButton(
                       onPressed: emailProvider.currentEmail == null
                           ? null
                           : () => emailProvider.refreshInbox(),
                       icon: emailProvider.isLoading
                           ? const SizedBox(
                               width: 16,
                               height: 16,
                               child: CircularProgressIndicator(
                                 strokeWidth: 2,
                                 valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                               ),
                             )
                           : const Icon(
                               Icons.refresh,
                               color: Color(0xFF00D4AA),
                               size: 16,
                             ),
                     );
                   },
                 ),
               ],
             ),
           ),
         ],
       ),
     );
   }

  Widget _buildNoEmailState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie animation
          SizedBox(
            width: 200,
            height: 200,
            child: Lottie.asset(
              'assets/animations/Contact.json',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Email Address',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate an email address first to start receiving emails',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInboxState(EmailProvider emailProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie animation
          SizedBox(
            width: 200,
            height: 200,
            child: Lottie.asset(
              'assets/animations/Contact.json',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Inbox is Empty',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No emails received yet. Check back later!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableEmailList(EmailProvider emailProvider, bool isPremium) {
    return Column(
      children: [
        // Delete All Button
        if (emailProvider.emails.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showDeleteAllDialog(context, emailProvider),
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Delete All Emails'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

        // Email List with proper padding to avoid ad overlap
        ...emailProvider.emails.asMap().entries.map((entry) {
          final index = entry.key;
          final email = entry.value;
          return Container(
            margin: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: index == emailProvider.emails.length - 1 
                ? (isPremium ? 16 : 320) // Extra bottom padding for ad space
                : 12,
            ),
            child: _buildEmailCard(email, emailProvider, index),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEmailCard(EmailModel email, EmailProvider emailProvider, int index) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2434),
        borderRadius: BorderRadius.circular(16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showEmailDetails(context, email),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with sender info and actions
                Row(
                  children: [
                    // Sender avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00D4AA),
                            const Color(0xFF00D4AA).withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          email.from.isNotEmpty 
                              ? email.from[0].toUpperCase() 
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Sender info and time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  email.from,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Attachment indicator
                              if (email.attachments.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00D4AA).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.attach_file,
                                        color: Color(0xFF00D4AA),
                                        size: 12,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${email.attachments.length}',
                                        style: const TextStyle(
                                          color: Color(0xFF00D4AA),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Colors.white54,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                email.timeAgo,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                email.formattedDate,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Delete button
                    IconButton(
                      onPressed: () => _showDeleteDialog(context, emailProvider, email, index),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Subject
                Text(
                  email.subject.isNotEmpty ? email.subject : 'No Subject',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Message preview
                if (email.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1C2E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00D4AA).withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      email.text,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                
                // Bottom row with indicators
                const SizedBox(height: 12),
                Row(
                  children: [
                    // HTML content indicator
                    if (email.html.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4AA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.code,
                              color: Color(0xFF00D4AA),
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Rich Content',
                              style: TextStyle(
                                color: Color(0xFF00D4AA),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    
                    const Spacer(),
                    
                    // Tap to view indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tap to view',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white54,
                            size: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailList(EmailProvider emailProvider) {
    return Column(
      children: [
        // Delete All Button
        if (emailProvider.emails.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showDeleteAllDialog(context, emailProvider),
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Delete All Emails'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

        // Email List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: emailProvider.emails.length,
            itemBuilder: (context, index) {
              final email = emailProvider.emails[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2434),
                  borderRadius: BorderRadius.circular(16),
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
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showEmailDetails(context, email),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row with sender info and actions
                          Row(
                            children: [
                              // Sender avatar
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF00D4AA),
                                      const Color(0xFF00D4AA).withOpacity(0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Center(
                                  child: Text(
                                    email.from.isNotEmpty 
                                        ? email.from[0].toUpperCase() 
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              // Sender info and time
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            email.from,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // Attachment indicator
                                        if (email.attachments.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF00D4AA).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.attach_file,
                                                  color: Color(0xFF00D4AA),
                                                  size: 12,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${email.attachments.length}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF00D4AA),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          color: Colors.white54,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          email.timeAgo,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          email.formattedDate,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Delete button
                              IconButton(
                                onPressed: () => _showDeleteDialog(context, emailProvider, email, index),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Subject
                          Text(
                            email.subject.isNotEmpty ? email.subject : 'No Subject',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          // Message preview
                          if (email.text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F1C2E),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF00D4AA).withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                email.text,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          
                          // Bottom row with indicators
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // HTML content indicator
                              if (email.html.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00D4AA).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.code,
                                        color: Color(0xFF00D4AA),
                                        size: 12,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Rich Content',
                                        style: TextStyle(
                                          color: Color(0xFF00D4AA),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              
                              const Spacer(),
                              
                              // Tap to view indicator
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Tap to view',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white54,
                                      size: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEmailDetails(BuildContext context, EmailModel email) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailDetailScreen(email: email),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, EmailProvider emailProvider, EmailModel email, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2434),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Email',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this email?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              emailProvider.deleteMessage(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context, EmailProvider emailProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2434),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete All Emails',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete all emails? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              emailProvider.deleteInbox();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoEmailStateWithConstraints(EmailProvider emailProvider, bool isPremium) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;
        final appBarHeight = 200.0;
        final adHeight = isPremium ? 0.0 : 320.0;
        final availableHeight = screenHeight - appBarHeight - adHeight - 40;
        
        return SizedBox(
          height: availableHeight,
          child: ListView(
            children: [
              SizedBox(
                height: availableHeight,
                child: _buildNoEmailState(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyInboxStateWithConstraints(EmailProvider emailProvider, bool isPremium) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.of(context).size.height;
        final appBarHeight = 200.0;
        final adHeight = isPremium ? 0.0 : 320.0;
        final availableHeight = screenHeight - appBarHeight - adHeight - 40;
        
        return SizedBox(
          height: availableHeight,
          child: ListView(
            children: [
              SizedBox(
                height: availableHeight,
                child: _buildEmptyInboxState(emailProvider),
              ),
            ],
          ),
        );
      },
    );
  }
}