# TurboMail API Documentation

## Overview
This API provides **3 simple GET endpoints** to fetch all data from MongoDB Atlas database. All data is managed through the admin panel.

## Base URL
```
https://your-domain.com
```

## Authentication
All endpoints require an API key parameter:
```
?key=your_api_key
```

---

## 📱 **API Endpoints**

### 1. iOS Ads API
**Get all iOS ad IDs**
```
GET /api/ios-ads?key=your_api_key
```

**Response:**
```json
{
  "success": true,
  "data": {
    "banner_ad_id": "ca-app-pub-ios/banner",
    "interstitial_ad_id": "ca-app-pub-ios/interstitial", 
    "rewarded_ad_id": "ca-app-pub-ios/rewarded",
    "native_ad_id": "ca-app-pub-ios/native",
    "app_open_ad_id": "ca-app-pub-ios/app-open"
  }
}
```

### 2. Android Ads API
**Get all Android ad IDs**
```
GET /api/android-ads?key=your_api_key
```

**Response:**
```json
{
  "success": true,
  "data": {
    "banner_ad_id": "ca-app-pub-android/banner",
    "interstitial_ad_id": "ca-app-pub-android/interstitial",
    "rewarded_ad_id": "ca-app-pub-android/rewarded", 
    "native_ad_id": "ca-app-pub-android/native",
    "app_open_ad_id": "ca-app-pub-android/app-open"
  }
}
```

### 3. App Updates API
**Get all app update data**
```
GET /api/app-updates?key=your_api_key
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "64f8a1b2c3d4e5f6a7b8c9d0",
      "version_name": "1.3.0",
      "version_code": 130,
      "update_message": "New features and bug fixes!",
      "is_force_update": false,
      "is_active": true,
      "created_at": "2024-01-15T10:30:00.000Z"
    }
  ]
}
```

---

## 🚀 **Usage Examples**

### Flutter/Dart Example
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://your-domain.com';
  static const String apiKey = 'your_api_key';
  
  // Get iOS ads
  static Future<Map<String, dynamic>> getIosAds() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/ios-ads?key=$apiKey')
    );
    return json.decode(response.body);
  }
  
  // Get Android ads  
  static Future<Map<String, dynamic>> getAndroidAds() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/android-ads?key=$apiKey')
    );
    return json.decode(response.body);
  }
  
  // Get app updates
  static Future<Map<String, dynamic>> getAppUpdates() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/app-updates?key=$apiKey')
    );
    return json.decode(response.body);
  }
}

// Usage in your app
void loadAds() async {
  if (Platform.isIOS) {
    final iosAds = await ApiService.getIosAds();
    final bannerAdId = iosAds['data']['banner_ad_id'];
    // Use the ad ID...
  } else if (Platform.isAndroid) {
    final androidAds = await ApiService.getAndroidAds();
    final bannerAdId = androidAds['data']['banner_ad_id'];
    // Use the ad ID...
  }
}

void checkForUpdates() async {
  final updates = await ApiService.getAppUpdates();
  final activeUpdate = updates['data'].firstWhere(
    (update) => update['is_active'] == true,
    orElse: () => null
  );
  
  if (activeUpdate != null) {
    // Show update dialog...
  }
}
```

### JavaScript Example
```javascript
const API_BASE = 'https://your-domain.com';
const API_KEY = 'your_api_key';

// Get iOS ads
async function getIosAds() {
  const response = await fetch(`${API_BASE}/api/ios-ads?key=${API_KEY}`);
  return await response.json();
}

// Get Android ads
async function getAndroidAds() {
  const response = await fetch(`${API_BASE}/api/android-ads?key=${API_KEY}`);
  return await response.json();
}

// Get app updates
async function getAppUpdates() {
  const response = await fetch(`${API_BASE}/api/app-updates?key=${API_KEY}`);
  return await response.json();
}

// Usage
getIosAds().then(data => {
  console.log('iOS Banner Ad ID:', data.data.banner_ad_id);
});

getAppUpdates().then(data => {
  const activeUpdate = data.data.find(update => update.is_active);
  if (activeUpdate) {
    console.log('Active update:', activeUpdate.version_name);
  }
});
```

---

## 🔧 **Admin Panel Management**

All data is managed through the admin panel at:
```
https://your-domain.com:3009/database
```

**Features:**
- ✅ Update iOS ad IDs
- ✅ Update Android ad IDs  
- ✅ Create new app updates
- ✅ Activate/deactivate updates
- ✅ Delete old updates
- ✅ View all data in real-time

---

## 📱 Flutter/Dart Integration Example

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://your-domain.com';
  static const String apiKey = 'your_api_key';
  
  // Get iOS ads
  static Future<Map<String, dynamic>> getIOSAds() async {
    final response = await http.get(
      Uri.parse('$baseUrl/ads/ios?key=$apiKey'),
    );
    return json.decode(response.body);
  }
  
  // Get Android ads
  static Future<Map<String, dynamic>> getAndroidAds() async {
    final response = await http.get(
      Uri.parse('$baseUrl/ads/android?key=$apiKey'),
    );
    return json.decode(response.body);
  }
  
  // Check for updates
  static Future<Map<String, dynamic>> checkForUpdates(int currentVersionCode) async {
    final response = await http.get(
      Uri.parse('$baseUrl/app/check-update?key=$apiKey&current_version_code=$currentVersionCode'),
    );
    return json.decode(response.body);
  }
}

// Usage in your app
void loadAds() async {
  try {
    Map<String, dynamic> ads;
    
    if (Platform.isIOS) {
      ads = await ApiService.getIOSAds();
    } else {
      ads = await ApiService.getAndroidAds();
    }
    
    // Use the ad IDs
    String bannerAdId = ads['banner_ad_id'];
    String interstitialAdId = ads['interstitial_ad_id'];
    // ... etc
    
  } catch (e) {
    print('Error loading ads: $e');
  }
}

void checkUpdates() async {
  try {
    const int currentVersion = 120; // Your app's current version code
    final updateInfo = await ApiService.checkForUpdates(currentVersion);
    
    if (updateInfo['update_available']) {
      if (updateInfo['is_force_update']) {
        // Show mandatory update dialog
        showForceUpdateDialog(updateInfo);
      } else {
        // Show optional update dialog
        showOptionalUpdateDialog(updateInfo);
      }
    }
  } catch (e) {
    print('Error checking updates: $e');
  }
}
```

---

## 🔧 Database Collections

The API automatically creates and manages three MongoDB collections:

1. **ads_ios** - Stores iOS ad configurations
2. **ads_android** - Stores Android ad configurations  
3. **app_updates** - Stores app update information

All collections are automatically initialized with default data when the API starts for the first time.

---

## ✅ Benefits of GET-Only API

- **Simple to use** - Just call URLs, no need for POST/PUT requests
- **Easy testing** - Test directly in browser
- **Mobile-friendly** - Works with simple HTTP GET requests
- **URL-based** - Can be bookmarked or saved
- **No JSON parsing needed** for requests