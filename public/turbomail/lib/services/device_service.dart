import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class DeviceService {
  static const String _deviceIdKey = 'turbomail_device_id';
  static String? _cachedDeviceId;
  
  /// Get unique device ID
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }
    
    final prefs = await SharedPreferences.getInstance();
    String? storedDeviceId = prefs.getString(_deviceIdKey);
    
    if (storedDeviceId != null) {
      _cachedDeviceId = storedDeviceId;
      return storedDeviceId;
    }
    
    // Generate new device ID
    String deviceId = await _generateDeviceId();
    await prefs.setString(_deviceIdKey, deviceId);
    _cachedDeviceId = deviceId;
    
    return deviceId;
  }
  
  /// Generate unique device ID based on device info
  static Future<String> _generateDeviceId() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String deviceId = '';
      
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = 'android_${androidInfo.id}_${androidInfo.model}_${androidInfo.brand}';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = 'ios_${iosInfo.identifierForVendor}_${iosInfo.model}';
      } else if (Platform.isWindows) {
        WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
        deviceId = 'windows_${windowsInfo.computerName}_${windowsInfo.userName}';
      } else if (Platform.isLinux) {
        LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
        deviceId = 'linux_${linuxInfo.machineId}_${linuxInfo.name}';
      } else if (Platform.isMacOS) {
        MacOsDeviceInfo macInfo = await deviceInfo.macOsInfo;
        deviceId = 'macos_${macInfo.systemGUID}_${macInfo.model}';
      } else {
        // Fallback for web or other platforms
        deviceId = 'web_${_generateRandomId()}';
      }
      
      // Clean and hash the device ID
      deviceId = deviceId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
      return 'tm_${deviceId.hashCode.abs()}_${DateTime.now().millisecondsSinceEpoch}';
      
    } catch (e) {
      // Fallback to random ID if device info fails
      return 'tm_fallback_${_generateRandomId()}_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
  
  /// Generate random ID as fallback
  static String _generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(16, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }
  
  /// Clear stored device ID (for testing purposes)
  static Future<void> clearDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
    _cachedDeviceId = null;
  }
  
  /// Get device info for display
  static Future<Map<String, String>> getDeviceInfo() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      Map<String, String> info = {};
      
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        info = {
          'platform': 'Android',
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'version': androidInfo.version.release,
        };
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        info = {
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'version': iosInfo.systemVersion,
        };
      } else if (Platform.isWindows) {
        WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
        info = {
          'platform': 'Windows',
          'computerName': windowsInfo.computerName,
          'userName': windowsInfo.userName,
        };
      } else {
        info = {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
        };
      }
      
      return info;
    } catch (e) {
      return {
        'platform': 'Unknown',
        'error': e.toString(),
      };
    }
  }
}