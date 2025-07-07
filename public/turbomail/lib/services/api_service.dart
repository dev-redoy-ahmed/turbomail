import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://165.22.97.51:3001';
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

}