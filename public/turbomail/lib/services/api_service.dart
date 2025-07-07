import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/email_models.dart';
import 'device_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3001';
  static const String apiKey = 'supersecretapikey123';
  static const Duration timeoutDuration = Duration(seconds: 30);
  
  // Cache for preventing duplicate requests
  static final Map<String, DateTime> _lastRequestTime = {};
  static const Duration minRequestInterval = Duration(seconds: 2);

  // Auto-generate random email
  static Future<Map<String, dynamic>> generateRandomEmail() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/generate?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to generate email: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Manually generate email
  static Future<Map<String, dynamic>> generateManualEmail(
      String username, String domain) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/generate/manual?username=$username&domain=$domain&key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to generate manual email: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get inbox for any email
  static Future<Map<String, dynamic>> getInbox(String email, {bool forceRefresh = false}) async {
    final cacheKey = 'inbox_$email';
    
    // Check if we should wait before making another request
    if (!forceRefresh && _lastRequestTime.containsKey(cacheKey)) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime[cacheKey]!);
      if (timeSinceLastRequest < minRequestInterval) {
        await Future.delayed(minRequestInterval - timeSinceLastRequest);
      }
    }
    
    try {
      _lastRequestTime[cacheKey] = DateTime.now();
      
      final response = await http.get(
        Uri.parse('$baseUrl/inbox/$email?key=$apiKey&t=${DateTime.now().millisecondsSinceEpoch}'),
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get inbox: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get specific message from inbox by index
  static Future<Map<String, dynamic>> getSpecificMessage(
      String email, int index) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/inbox/$email/$index?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Delete all messages from inbox
  static Future<Map<String, dynamic>> deleteAllMessages(String email) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/delete/$email?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to delete messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Delete specific message by index
  static Future<Map<String, dynamic>> deleteMessage(String email, int index) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/delete/$email/$index?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to delete message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // MongoDB API Methods
  
  // Store generated email in MongoDB
  static Future<Map<String, dynamic>> storeGeneratedEmail(GeneratedEmail email) async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      final emailData = email.toMongoJson();
      emailData['deviceId'] = deviceId;
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/mongodb/emails/store'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: json.encode(emailData),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to store email: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Get user's generated emails from MongoDB
  static Future<List<GeneratedEmail>> getUserGeneratedEmails() async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/mongodb/emails/user/$deviceId?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> emailsJson = data['emails'] ?? [];
        return emailsJson.map((json) => GeneratedEmail.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get user emails: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Update email status (active/inactive)
  static Future<Map<String, dynamic>> updateEmailStatus(String emailId, bool isActive) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/mongodb/emails/$emailId/status'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: json.encode({'isActive': isActive}),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update email status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Delete generated email from MongoDB
  static Future<Map<String, dynamic>> deleteGeneratedEmail(String emailId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/mongodb/emails/$emailId?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to delete email: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Get device info
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      final deviceInfo = await DeviceService.getDeviceInfo();
      
      return {
        'deviceId': deviceId,
        'deviceInfo': deviceInfo,
      };
    } catch (e) {
      throw Exception('Failed to get device info: $e');
    }
  }
}