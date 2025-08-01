import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/email_model.dart';
import 'device_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3001';
  static const String apiKey = 'tempmail-master-key-2024';
  static const List<String> availableDomains = ['oplex.online', 'agrovia.store'];

  // Cache keys
  static const String _adConfigCacheKey = 'ad_config_cache';
  static const String _appConfigCacheKey = 'app_config_cache';
  static const String _cacheTimestampKey = 'cache_timestamp';
  static const int _cacheValidityHours = 24; // Cache valid for 24 hours

  final Dio _dio = Dio();
  final Dio _adminDio = Dio();

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    
    _adminDio.options.connectTimeout = const Duration(seconds: 10);
    _adminDio.options.receiveTimeout = const Duration(seconds: 10);
  }

  /// Get available domains
  List<String> getAvailableDomains() {
    return availableDomains;
  }

  /// Generate a random email
  Future<GeneratedEmail> generateRandomEmail() async {
    final deviceId = await DeviceService.getDeviceId();
    
    try {
      final response = await _dio.get('/generate', queryParameters: {
        'key': apiKey,
        'deviceId': deviceId,
      });
      
      return GeneratedEmail.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to generate random email: $e');
    }
  }

  /// Generate a manual email with custom username
  Future<GeneratedEmail> generateManualEmail(String username, String domain) async {
    final deviceId = await DeviceService.getDeviceId();
    
    try {
      final response = await _dio.get('/generate/manual', queryParameters: {
        'key': apiKey,
        'username': username,
        'domain': domain,
        'deviceId': deviceId,
      });
      
      return GeneratedEmail.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 409) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
        throw Exception('This email is already taken. Please use a different name.');
      }
      throw Exception('Failed to generate manual email: $e');
    }
  }

  /// Check if email is available
  Future<bool> checkEmailAvailability(String email) async {
    try {
      final response = await _dio.get('/check/$email', queryParameters: {
        'key': apiKey,
      });
      
      return response.data['available'] ?? false;
    } catch (e) {
      throw Exception('Failed to check email availability: $e');
    }
  }

  /// Get inbox messages for an email
  Future<List<EmailModel>> getInboxMessages(String email) async {
    try {
      final response = await _dio.get('/inbox/$email', queryParameters: {
        'key': apiKey,
      });
      
      final List<dynamic> data = response.data;
      return data.map((json) => EmailModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get inbox messages: $e');
    }
  }

  /// Delete a specific message from inbox
  Future<void> deleteMessage(String email, int index) async {
    try {
      await _dio.delete('/delete/$email/$index', queryParameters: {
        'key': apiKey,
      });
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Delete entire inbox
  Future<void> deleteInbox(String email) async {
    try {
      await _dio.delete('/delete/$email', queryParameters: {
        'key': apiKey,
      });
    } catch (e) {
      throw Exception('Failed to delete inbox: $e');
    }
  }

  /// Get email history for current device
  Future<EmailHistoryResponse> getEmailHistory({int page = 1, int limit = 20}) async {
    final deviceId = await DeviceService.getDeviceId();
    
    try {
      final response = await _dio.get('/history/$deviceId', queryParameters: {
        'key': apiKey,
        'page': page,
        'limit': limit,
      });
      
      return EmailHistoryResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get email history: $e');
    }
  }

  /// Toggle star status for an email
  Future<void> toggleEmailStar(String email, bool isStarred) async {
    try {
      await _dio.put('/star/$email', 
        data: {'isStarred': isStarred},
        queryParameters: {'key': apiKey},
      );
    } catch (e) {
      throw Exception('Failed to toggle star: $e');
    }
  }

  /// Get starred emails for current device
  Future<List<HistoryEmailModel>> getStarredEmails() async {
    final deviceId = await DeviceService.getDeviceId();
    
    try {
      final response = await _dio.get('/starred/$deviceId', queryParameters: {
        'key': apiKey,
      });
      
      final List<dynamic> data = response.data['emails'];
      return data.map((json) => HistoryEmailModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get starred emails: $e');
    }
  }

  /// Delete email from history
  Future<void> deleteEmailFromHistory(String email) async {
    final deviceId = await DeviceService.getDeviceId();
    
    try {
      await _dio.delete('/history/$email', queryParameters: {
        'key': apiKey,
        'deviceId': deviceId,
      });
    } catch (e) {
      throw Exception('Failed to delete email from history: $e');
    }
  }

  /// Get app updates from VPS API
  Future<List<Map<String, dynamic>>> getAppUpdates() async {
    try {
      debugPrint('🔄 Fetching app updates from VPS...');
      final response = await _dio.get(
        '/api/app-updates',
        options: Options(
          headers: {
            'x-api-key': apiKey,
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final updates = List<Map<String, dynamic>>.from(response.data['data']);
        debugPrint('✅ Successfully fetched ${updates.length} app updates');
        return updates;
      }
      
      debugPrint('⚠️ No app updates found or invalid response');
      return [];
    } catch (e) {
      debugPrint('❌ Error fetching app updates: $e');
      throw Exception('Failed to get app updates: $e');
    }
  }

  // Cache management methods
  Future<bool> _isCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_cacheTimestampKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final cacheAge = now - timestamp;
    final maxAge = _cacheValidityHours * 60 * 60 * 1000; // Convert to milliseconds
    return cacheAge < maxAge;
  }

  Future<void> _saveCache(String key, String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, data);
    await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<String?> _getCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  /// Get ad configuration from API based on platform
  Future<AdConfig> getAdConfig() async {
    try {
      debugPrint('🔄 Fetching ad configuration...');
      
      // Check cache first
      if (await _isCacheValid()) {
        final cachedData = await _getCache(_adConfigCacheKey);
        if (cachedData != null) {
          try {
            final json = jsonDecode(cachedData) as Map<String, dynamic>;
            debugPrint('✅ Using cached ad config');
            return AdConfig.fromJson(json);
          } catch (e) {
            debugPrint('Error parsing cached ad config: $e');
            // Clear invalid cache
            await _clearSpecificCache(_adConfigCacheKey);
          }
        }
      }

      // Determine platform-specific endpoint
      String endpoint;
      if (Platform.isAndroid) {
        endpoint = '/api/ads/android';
        debugPrint('📱 Fetching Android ad configuration');
      } else if (Platform.isIOS) {
        endpoint = '/api/ads/ios';
        debugPrint('🍎 Fetching iOS ad configuration');
      } else {
        debugPrint('❌ Unsupported platform');
        return _getDefaultAdConfig();
      }

      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: {
            'x-api-key': apiKey,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final adData = response.data['data'];
        debugPrint('✅ Ad config fetched successfully');
        debugPrint('📊 Ad data: $adData');

        // Transform the response to match AdConfig model
        final transformedData = {
          'interstitial_ad_id': adData['interstitial_ad_id'] ?? '',
          'banner_ad_id': adData['banner_ad_id'] ?? '',
          'app_open_ad_id': adData['app_open_ad_id'] ?? '',
          'rewarded_ad_id': adData['rewarded_ad_id'] ?? '',
          'native_ad_id': adData['native_ad_id'] ?? '',
          'ads_enabled': _hasValidAdIds(adData),
        };

        // Cache the transformed data
        await _saveCache(_adConfigCacheKey, jsonEncode(transformedData));
        
        return AdConfig.fromJson(transformedData);
      } else {
        debugPrint('❌ Failed to fetch ad config: ${response.data}');
        return _getDefaultAdConfig();
      }
    } catch (e) {
      debugPrint('❌ Error fetching ad config: $e');
      return _getDefaultAdConfig();
    }
  }

  // Helper method to check if any ad IDs are valid
  bool _hasValidAdIds(Map<String, dynamic> adData) {
    final interstitial = adData['interstitial_ad_id']?.toString() ?? '';
    final banner = adData['banner_ad_id']?.toString() ?? '';
    final appOpen = adData['app_open_ad_id']?.toString() ?? '';
    
    return interstitial.isNotEmpty || banner.isNotEmpty || appOpen.isNotEmpty;
  }

  // Get default ad configuration
  AdConfig _getDefaultAdConfig() {
    debugPrint('Using default ad configuration');
    return AdConfig.fromJson({});
  }

  /// Get app configuration from API
  Future<AppConfig> getAppConfig() async {
    try {
      // Check cache first
      if (await _isCacheValid()) {
        final cachedData = await _getCache(_appConfigCacheKey);
        if (cachedData != null) {
          try {
            final json = jsonDecode(cachedData) as Map<String, dynamic>;
            debugPrint('App configuration loaded from cache');
            return AppConfig.fromJson(json);
          } catch (e) {
            debugPrint('Error parsing cached app config: $e');
            // Clear invalid cache
            await _clearSpecificCache(_appConfigCacheKey);
          }
        }
      }

      debugPrint('Fetching app config from API');

      // Fetch from API
      final response = await _dio.get('/api/app-updates', queryParameters: {
        'key': apiKey,
      });

      if (response.statusCode == 200) {
        // Transform the response to match our AppConfig model
        final data = response.data['data'];
        final transformedData = {
          'latest_version': data['latest_version'] ?? '1.0.0',
          'minimum_version': data['minimum_version'] ?? '1.0.0',
          'update_url': data['update_url'] ?? '',
          'force_update': data['force_update'] ?? false,
          'update_message': data['update_message'] ?? '',
        };
        
        // Save to cache as JSON string
        await _saveCache(_appConfigCacheKey, jsonEncode(transformedData));
        
        debugPrint('App configuration loaded from API');
        return AppConfig.fromJson(transformedData);
      } else {
        throw Exception('Failed to load app config: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching app config: $e');
      
      // Try to return cached data even if expired
      final cachedData = await _getCache(_appConfigCacheKey);
      if (cachedData != null) {
        try {
          final json = jsonDecode(cachedData) as Map<String, dynamic>;
          debugPrint('App configuration loaded from expired cache');
          return AppConfig.fromJson(json);
        } catch (e) {
          debugPrint('Error parsing expired cached app config: $e');
          await _clearSpecificCache(_appConfigCacheKey);
        }
      }
      
      // Return default config if all else fails
      debugPrint('Using default app configuration');
      return AppConfig.fromJson({});
    }
  }

  /// Clear specific cache
  Future<void> _clearSpecificCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  /// Clear cache
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adConfigCacheKey);
    await prefs.remove(_appConfigCacheKey);
    await prefs.remove(_cacheTimestampKey);
  }

  /// Force refresh cache
  Future<void> refreshCache() async {
    await clearCache();
    await getAdConfig();
    await getAppConfig();
  }
}

/// Model for email history response
class EmailHistoryResponse {
  final List<HistoryEmailModel> emails;
  final PaginationInfo pagination;

  EmailHistoryResponse({
    required this.emails,
    required this.pagination,
  });

  factory EmailHistoryResponse.fromJson(Map<String, dynamic> json) {
    return EmailHistoryResponse(
      emails: (json['emails'] as List)
          .map((e) => HistoryEmailModel.fromJson(e))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination']),
    );
  }
}

/// Model for pagination information
class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int pages;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'],
      limit: json['limit'],
      total: json['total'],
      pages: json['pages'],
    );
  }
}

/// Model for history email entries
class HistoryEmailModel {
  final String id;
  final String email;
  final String deviceId;
  final String type;
  final bool isStarred;
  final DateTime createdAt;
  final DateTime lastUsed;
  final String? username;
  final String? domain;

  HistoryEmailModel({
    required this.id,
    required this.email,
    required this.deviceId,
    required this.type,
    required this.isStarred,
    required this.createdAt,
    required this.lastUsed,
    this.username,
    this.domain,
  });

  factory HistoryEmailModel.fromJson(Map<String, dynamic> json) {
    return HistoryEmailModel(
      id: json['_id'],
      email: json['email'],
      deviceId: json['deviceId'],
      type: json['type'],
      isStarred: json['isStarred'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      lastUsed: DateTime.parse(json['lastUsed']),
      username: json['username'],
      domain: json['domain'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'deviceId': deviceId,
      'type': type,
      'isStarred': isStarred,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed.toIso8601String(),
      'username': username,
      'domain': domain,
    };
  }
}

/// Ad configuration model
class AdConfig {
  final String bannerId;
  final String interstitialId;
  final String rewardedId;
  final String nativeId;
  final String appOpenId;
  final bool adsEnabled;

  AdConfig({
    required this.bannerId,
    required this.interstitialId,
    required this.rewardedId,
    required this.nativeId,
    required this.appOpenId,
    required this.adsEnabled,
  });

  factory AdConfig.fromJson(Map<String, dynamic> json) {
    return AdConfig(
      bannerId: json['banner_ad_id'] ?? '',
      interstitialId: json['interstitial_ad_id'] ?? '',
      rewardedId: json['rewarded_ad_id'] ?? '',
      nativeId: json['native_ad_id'] ?? '',
      appOpenId: json['app_open_ad_id'] ?? '',
      adsEnabled: json['ads_enabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'banner_ad_id': bannerId,
      'interstitial_ad_id': interstitialId,
      'rewarded_ad_id': rewardedId,
      'native_ad_id': nativeId,
      'app_open_ad_id': appOpenId,
      'ads_enabled': adsEnabled,
    };
  }
}

/// App configuration model
class AppConfig {
  final String latestVersion;
  final String minimumVersion;
  final String updateUrl;
  final bool forceUpdate;
  final String updateMessage;

  AppConfig({
    required this.latestVersion,
    required this.minimumVersion,
    required this.updateUrl,
    required this.forceUpdate,
    required this.updateMessage,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      latestVersion: json['latest_version'] ?? '1.0.0',
      minimumVersion: json['minimum_version'] ?? '1.0.0',
      updateUrl: json['update_url'] ?? '',
      forceUpdate: json['force_update'] ?? false,
      updateMessage: json['update_message'] ?? 'A new version is available!',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latest_version': latestVersion,
      'minimum_version': minimumVersion,
      'update_url': updateUrl,
      'force_update': forceUpdate,
      'update_message': updateMessage,
    };
  }
}