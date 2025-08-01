import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';

class DeviceService {
  static const String _deviceIdKey = 'device_id';
  static String? _cachedDeviceId;

  /// Get or generate a unique device ID using real device identifiers
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) {
      print('🔍 Retrieved cached Device ID: $_cachedDeviceId');
      return _cachedDeviceId!;
    }

    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      // Get real device ID based on platform
      deviceId = await _getRealDeviceId();
      await prefs.setString(_deviceIdKey, deviceId);
      print('🔍 Generated new Device ID: $deviceId');
    } else {
      print('🔍 Retrieved existing Device ID: $deviceId');
    }

    _cachedDeviceId = deviceId;
    return deviceId;
  }

  /// Get stable device ID based on hardware fingerprint + persistent UUID
  static Future<String> _getRealDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    
    try {
      String hardwareFingerprint = '';
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Create fingerprint from multiple hardware identifiers
        hardwareFingerprint = '${androidInfo.brand}_${androidInfo.model}_${androidInfo.board}_${androidInfo.hardware}';
        print('🔍 Android Hardware Fingerprint: $hardwareFingerprint');
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        // Create fingerprint from iOS device info
        hardwareFingerprint = '${iosInfo.model}_${iosInfo.systemName}_${iosInfo.utsname.machine}';
        print('🔍 iOS Hardware Fingerprint: $hardwareFingerprint');
      } else {
        // For web/desktop, use a stable identifier
        try {
          hardwareFingerprint = 'web_${Platform.operatingSystem}';
        } catch (e) {
          // Platform.operatingSystem not supported on web
          hardwareFingerprint = 'web_browser';
        }
        print('🔍 Web/Desktop Fingerprint: $hardwareFingerprint');
      }
      
      // Generate stable device ID from hardware fingerprint
      final stableDeviceId = _generateStableId(hardwareFingerprint);
      print('🔍 Generated Stable Device ID: $stableDeviceId');
      return stableDeviceId;
      
    } catch (e) {
      // Fallback to UUID if device info fails
      final deviceId = _generateFallbackId();
      print('🔍 Error generating device ID, using UUID: $deviceId');
      return deviceId;
    }
  }

  /// Generate stable device ID from hardware fingerprint
  static String _generateStableId(String hardwareFingerprint) {
    // Create a hash from the hardware fingerprint for consistency
    final bytes = utf8.encode(hardwareFingerprint);
    final digest = sha256.convert(bytes);
    
    // Use first 32 characters of the hash as device ID
    return digest.toString().substring(0, 32);
  }
  
  /// Generate fallback UUID when real device ID is not available
  static String _generateFallbackId() {
    const uuid = Uuid();
    return uuid.v4();
  }

  /// Get device info for display purposes
  static Future<Map<String, String>> getDeviceInfo() async {
    final deviceId = await getDeviceId();
    final deviceInfo = DeviceInfoPlugin();
    
    String platformName = 'Unknown';
    String deviceModel = 'Unknown';
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        platformName = 'Android ${androidInfo.version.release}';
        deviceModel = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        platformName = '${iosInfo.systemName} ${iosInfo.systemVersion}';
        deviceModel = iosInfo.model;
      } else {
        platformName = Platform.operatingSystem;
        deviceModel = Platform.operatingSystemVersion;
      }
    } catch (e) {
      platformName = Platform.operatingSystem;
      deviceModel = Platform.operatingSystemVersion;
    }
    
    return {
      'deviceId': deviceId,
      'platform': platformName,
      'model': deviceModel,
    };
  }

  /// Clear device ID (for testing purposes)
  static Future<void> clearDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
    _cachedDeviceId = null;
  }
}