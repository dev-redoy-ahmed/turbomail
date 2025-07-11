class GeneratedEmail {
  final String email;
  final String type;
  final int ttl;
  final DateTime? expiresAt;
  final String? deviceId;
  final String? id;
  final DateTime? createdAt;
  bool isActive;

  GeneratedEmail({
    required this.email,
    required this.type,
    required this.ttl,
    this.expiresAt,
    this.deviceId,
    this.id,
    this.createdAt,
    this.isActive = true,
  });

  factory GeneratedEmail.fromJson(Map<String, dynamic> json) {
    return GeneratedEmail(
      email: json['email'] ?? '',
      type: json['type'] ?? '',
      ttl: json['ttl'] ?? 0,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      deviceId: json['deviceId'],
      id: json['id'] ?? json['_id'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'type': type,
      'ttl': ttl,
      'expiresAt': expiresAt?.toIso8601String(),
      'deviceId': deviceId,
      'id': id,
      'createdAt': createdAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toMongoJson() {
    return {
      'email': email,
      'type': type,
      'ttl': ttl,
      'expiresAt': expiresAt?.toIso8601String(),
      'deviceId': deviceId,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'isActive': isActive,
    };
  }

  String get formattedTimestamp {
    if (expiresAt == null) return 'No expiration';
    try {
      return '${expiresAt!.day}/${expiresAt!.month}/${expiresAt!.year} ${expiresAt!.hour}:${expiresAt!.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}

class EmailMessage {
  final String from;
  final List<String> to;
  final int? timestamp;
  final String content;
  final String subject;
  final String? id;
  final List<String> attachments;

  EmailMessage({
    required this.from,
    required this.to,
    this.timestamp,
    required this.content,
    required this.subject,
    this.id,
    this.attachments = const [],
  });

  factory EmailMessage.fromJson(Map<String, dynamic> json) {
    return EmailMessage(
      from: json['from'] ?? '',
      to: json['to'] != null ? List<String>.from(json['to']) : [],
      timestamp: json['timestamp'],
      content: json['content'] ?? '',
      subject: json['subject'] ?? '',
      id: json['id'],
      attachments: json['attachments'] != null ? List<String>.from(json['attachments']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'timestamp': timestamp,
      'content': content,
      'subject': subject,
      'id': id,
      'attachments': attachments,
    };
  }

  String get formattedDate {
    if (timestamp == null) return 'Unknown';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp!);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get shortContent {
    if (content.isEmpty) return 'No content';
    return content.length > 100 ? '${content.substring(0, 100)}...' : content;
  }
}

class Inbox {
  final String email;
  final List<EmailMessage> messages;
  final int count;
  final String timestamp;

  Inbox({
    required this.email,
    required this.messages,
    required this.count,
    required this.timestamp,
  });

  factory Inbox.fromJson(Map<String, dynamic> json) {
    return Inbox(
      email: json['email'] ?? '',
      messages: json['messages'] != null
          ? (json['messages'] as List)
              .map((msg) => EmailMessage.fromJson(msg))
              .toList()
          : [],
      count: json['count'] ?? 0,
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'count': count,
      'timestamp': timestamp,
    };
  }
}

class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.success(String message, [dynamic data]) {
    return ApiResponse(
      success: true,
      message: message,
      data: data,
    );
  }

  factory ApiResponse.error(String message) {
    return ApiResponse(
      success: false,
      message: message,
    );
  }
}