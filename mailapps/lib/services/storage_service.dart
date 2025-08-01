import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _lastEmailKey = 'last_generated_email';
  static const String _hasGeneratedEmailKey = 'has_generated_email';
  
  static SharedPreferences? _prefs;
  
  /// Initialize SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  /// Save the last generated email
  static Future<void> saveLastEmail(String email) async {
    await init();
    await _prefs!.setString(_lastEmailKey, email);
    await _prefs!.setBool(_hasGeneratedEmailKey, true);
  }
  
  /// Get the last generated email
  static Future<String?> getLastEmail() async {
    await init();
    return _prefs!.getString(_lastEmailKey);
  }
  
  /// Check if user has ever generated an email
  static Future<bool> hasGeneratedEmail() async {
    await init();
    return _prefs!.getBool(_hasGeneratedEmailKey) ?? false;
  }
  
  /// Clear stored email data
  static Future<void> clearEmailData() async {
    await init();
    await _prefs!.remove(_lastEmailKey);
    await _prefs!.remove(_hasGeneratedEmailKey);
  }
  
  /// Check if this is the first time opening the app
  static Future<bool> isFirstTime() async {
    await init();
    return !(await hasGeneratedEmail());
  }
}