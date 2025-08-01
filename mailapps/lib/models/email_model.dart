class EmailModel {
  final String id;
  final String from;
  final String to;
  final String subject;
  final String text;
  final String html;
  final String date;
  final DateTime receivedAt;
  final List<EmailAttachment> attachments;

  EmailModel({
    required this.id,
    required this.from,
    required this.to,
    required this.subject,
    required this.text,
    required this.html,
    required this.date,
    DateTime? receivedAt,
    required this.attachments,
  }) : receivedAt = receivedAt ?? DateTime.now();

  // Getters for compatibility
  String get textContent => text;
  String get htmlContent => html;

  // Get formatted time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(receivedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Get formatted date for display
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final emailDate = DateTime(receivedAt.year, receivedAt.month, receivedAt.day);
    
    if (emailDate == today) {
      // Today - show time
      final hour = receivedAt.hour;
      final minute = receivedAt.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (emailDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday';
    } else if (now.difference(receivedAt).inDays < 7) {
      // This week - show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[receivedAt.weekday - 1];
    } else {
      // Older - show date
      final month = receivedAt.month.toString().padLeft(2, '0');
      final day = receivedAt.day.toString().padLeft(2, '0');
      return '$month/$day/${receivedAt.year}';
    }
  }

  factory EmailModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    
    // Try to parse the date from various formats
    if (json['date'] != null && json['date'].toString().isNotEmpty) {
      try {
        // Try parsing ISO format first
        parsedDate = DateTime.parse(json['date']);
      } catch (e) {
        try {
          // Try parsing RFC 2822 format (common in emails)
          parsedDate = DateTime.tryParse(json['date']);
        } catch (e) {
          // If all parsing fails, use current time
          parsedDate = DateTime.now();
        }
      }
    }
    
    // If receivedAt is provided in JSON, use it
    if (json['receivedAt'] != null) {
      try {
        parsedDate = DateTime.parse(json['receivedAt']);
      } catch (e) {
        // Keep the parsed date from above or current time
      }
    }
    
    return EmailModel(
      id: json['id'] ?? '',
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      subject: json['subject'] ?? '',
      text: json['text'] ?? '',
      html: json['html'] ?? '',
      date: json['date'] ?? '',
      receivedAt: parsedDate ?? DateTime.now(),
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => EmailAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'subject': subject,
      'text': text,
      'html': html,
      'date': date,
      'receivedAt': receivedAt.toIso8601String(),
      'attachments': attachments.map((e) => e.toJson()).toList(),
    };
  }
}

class EmailAttachment {
  final String filename;
  final String contentType;
  final int size;

  EmailAttachment({
    required this.filename,
    required this.contentType,
    required this.size,
  });

  factory EmailAttachment.fromJson(Map<String, dynamic> json) {
    return EmailAttachment(
      filename: json['filename'] ?? '',
      contentType: json['contentType'] ?? '',
      size: json['size'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'contentType': contentType,
      'size': size,
    };
  }
}

class GeneratedEmail {
  final String email;
  final String token;

  GeneratedEmail({
    required this.email,
    required this.token,
  });

  factory GeneratedEmail.fromJson(Map<String, dynamic> json) {
    return GeneratedEmail(
      email: json['email'] ?? '',
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'token': token,
    };
  }
}