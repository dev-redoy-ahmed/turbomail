# TurboMail Flutter Integration Guide

## Overview
This guide explains how to integrate the ads and app updates functionality in your TurboMail Flutter app.

## Features Implemented

### 1. Ads Management
- **Banner Ads**: Display banner ads in your app screens
- **Interstitial Ads**: Show full-screen ads between app transitions
- **Rewarded Ads**: Offer rewards for watching ads
- **Native Ads**: Integrate ads that match your app's design
- **App Open Ads**: Show ads when the app is opened
- **Rewarded Interstitial Ads**: Combination of interstitial and rewarded ads

### 2. App Updates
- **Force Updates**: Mandatory updates that block app usage
- **Normal Updates**: Optional updates with user choice
- **Platform-specific**: Different update configurations for Android and iOS
- **Version Comparison**: Automatic version checking and comparison

## API Configuration

### Base URLs
```dart
// Local Development
static const String _baseUrl = 'http://localhost:3001';

// Production VPS (Replace with your VPS IP)
static const String _baseUrl = 'http://YOUR_VPS_IP:3001';
```

### API Key
```dart
static const String _apiKey = 'tempmail-master-key-2024';
```

## Services

### AdsService
Located at: `lib/services/ads_service.dart`

**Key Methods:**
- `initialize()`: Initialize the ads service and fetch configurations
- `loadBannerAd()`: Load and return a banner ad
- `showInterstitialAd()`: Show an interstitial ad
- `showRewardedAd()`: Show a rewarded ad
- `showAppOpenAd()`: Show an app open ad

**Usage Example:**
```dart
// Initialize in main.dart
await AdsService().initialize();

// Load banner ad
final bannerAd = await AdsService().loadBannerAd();

// Show interstitial ad
final success = await AdsService().showInterstitialAd();

// Show rewarded ad
await AdsService().showRewardedAd(
  onUserEarnedReward: () {
    // Grant reward to user
  },
);
```

### AppUpdateService
Located at: `lib/services/app_update_service.dart`

**Key Methods:**
- `checkForUpdates()`: Check if updates are available
- `showUpdateDialog()`: Show update dialog to user
- `getCurrentAppVersion()`: Get current app version info
- `isUpdateAvailable()`: Compare versions

**Usage Example:**
```dart
// Check for updates
final update = await AppUpdateService.instance.checkForUpdates();

// Show update dialog if available
if (update != null) {
  await AppUpdateService.instance.showUpdateDialog(context, update);
}
```

## Widgets

### AdBannerWidget
Located at: `lib/widgets/ad_widgets.dart`

A reusable widget for displaying banner ads.

**Usage:**
```dart
const AdBannerWidget(
  adSize: AdSize.banner,
  margin: EdgeInsets.all(8.0),
)
```

### AdInterstitialHelper
Helper class for showing interstitial ads with callbacks.

**Usage:**
```dart
AdInterstitialHelper.showInterstitialAd(
  onAdClosed: () {
    // Navigate or perform action after ad
  },
  onAdFailedToShow: () {
    // Handle ad failure
  },
);
```

### AdRewardedHelper
Helper class for showing rewarded ads.

**Usage:**
```dart
AdRewardedHelper.showRewardedAd(
  onUserEarnedReward: () {
    // Grant reward to user
  },
  onAdFailedToShow: () {
    // Handle ad failure
  },
);
```

## Models

### AdsConfig
Located at: `lib/models/ads_model.dart`

Represents an ad configuration from the API.

**Properties:**
- `id`: Unique identifier
- `adType`: Type of ad (banner, interstitial, etc.)
- `adId`: Google AdMob ad unit ID
- `platform`: Target platform (android, ios, both)
- `description`: Ad description
- `isActive`: Whether the ad is active
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp

### AppUpdateModel
Located at: `lib/models/ads_model.dart`

Represents an app update configuration.

**Properties:**
- `id`: Unique identifier
- `versionName`: Version string (e.g., "1.2.0")
- `versionCode`: Version number
- `platform`: Target platform
- `isForceUpdate`: Whether update is mandatory
- `isNormalUpdate`: Whether update is optional
- `isActive`: Whether update is active
- `updateMessage`: Message to show to user
- `updateLink`: Download link for update
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp

## Integration Examples

### 1. Adding Banner Ads to Screens

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Screen')),
      body: Column(
        children: [
          // Banner ad at top
          const AdBannerWidget(
            margin: EdgeInsets.all(8.0),
          ),
          
          Expanded(
            child: YourContent(),
          ),
          
          // Banner ad at bottom
          const AdBannerWidget(
            margin: EdgeInsets.all(8.0),
          ),
        ],
      ),
    );
  }
}
```

### 2. Showing Interstitial Ads on Navigation

```dart
void navigateToNextScreen() {
  AdInterstitialHelper.showInterstitialAd(
    onAdClosed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NextScreen()),
      );
    },
  );
}
```

### 3. Rewarded Ads for Premium Features

```dart
void unlockPremiumFeature() {
  AdRewardedHelper.showRewardedAd(
    onUserEarnedReward: () {
      // Grant premium access
      PremiumProvider.of(context).unlockFeature();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Premium feature unlocked!')),
      );
    },
    onAdFailedToShow: () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ad not available. Try again later.')),
      );
    },
  );
}
```

### 4. App Update Check on Startup

```dart
class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    final update = await AppUpdateService.instance.checkForUpdates();
    if (update != null && mounted) {
      await AppUpdateService.instance.showUpdateDialog(context, update);
    }
  }
}
```

## API Endpoints

### Ads Configuration
**Endpoint:** `GET /ads-config`
**Parameters:**
- `platform`: android | ios | both
- `key`: API key for authentication

**Response:**
```json
{
  "success": true,
  "ads": [
    {
      "_id": "...",
      "adType": "banner",
      "adId": "ca-app-pub-...",
      "platform": "android",
      "description": "Banner ad for Android",
      "isActive": true,
      "createdAt": "2024-01-01T00:00:00.000Z",
      "updatedAt": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

### App Updates
**Endpoint:** `GET /app-updates`
**Parameters:**
- `platform`: android | ios
- `key`: API key for authentication

**Response:**
```json
{
  "success": true,
  "hasUpdate": true,
  "update": {
    "_id": "...",
    "versionName": "1.2.0",
    "versionCode": 12,
    "platform": "android",
    "isForceUpdate": false,
    "isNormalUpdate": true,
    "isActive": true,
    "updateMessage": "New features and bug fixes",
    "updateLink": "https://play.google.com/store/apps/details?id=...",
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z"
  }
}
```

## Configuration for Production

### 1. Update API URLs
Replace localhost URLs with your VPS IP:

```dart
// In ads_service.dart
String get _mailApiUrl => 'http://YOUR_VPS_IP:3001/ads-config';

// In app_update_service.dart
static const String _baseUrl = 'http://YOUR_VPS_IP:3001';
```

### 2. Update API Key
Make sure to use the correct API key that matches your backend configuration.

### 3. Test Ad IDs
Replace test ad IDs with your actual Google AdMob ad unit IDs in the admin panel.

## Testing

### 1. Local Testing
1. Start the mail API server: `node index.js`
2. Start the admin panel: `node server.js`
3. Configure ads and app updates in the admin panel
4. Run the Flutter app and test functionality

### 2. Production Testing
1. Deploy your backend to VPS
2. Update Flutter app URLs to point to VPS
3. Test ads and app updates functionality
4. Verify API key authentication

## Troubleshooting

### Common Issues

1. **Ads not loading**
   - Check if ad IDs are correctly configured in admin panel
   - Verify API connectivity
   - Check Google AdMob account status

2. **App updates not working**
   - Verify API endpoint is accessible
   - Check version comparison logic
   - Ensure update links are valid

3. **API authentication errors**
   - Verify API key is correct
   - Check if API key matches backend configuration

### Debug Logs
Both services include comprehensive logging. Check the console for debug information:

```
🚀 Initializing Ads Service...
✅ Mobile Ads SDK initialized
📡 Fetching ads config from mail API...
✅ Updated banner: ca-app-pub-... (Active)
✅ Ads config fetched successfully
```

## Security Notes

1. **API Key**: Keep your API key secure and don't expose it in client-side code in production
2. **HTTPS**: Use HTTPS for production API endpoints
3. **Validation**: Always validate API responses before using them
4. **Error Handling**: Implement proper error handling for network failures

## Performance Tips

1. **Preload Ads**: Load ads in advance for better user experience
2. **Cache Configuration**: Cache ads and update configurations locally
3. **Lazy Loading**: Load ads only when needed to save bandwidth
4. **Background Updates**: Check for updates in the background

This integration provides a complete ads and app updates system for your TurboMail Flutter app with proper error handling, caching, and user experience considerations.