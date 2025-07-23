# TurboMail - Ads & App Updates Integration

## Overview
This update adds MongoDB-based ads management and app updates functionality to the TurboMail project. The system now supports managing advertisement configurations and app version updates through the admin panel.

## New Features

### 1. Ads Management
- **Admin Panel**: Complete interface for managing ad configurations
- **MongoDB Storage**: All ad settings stored in MongoDB Atlas
- **Platform Support**: Android, iOS, or both platforms
- **Ad Types**: Banner, Interstitial, Rewarded, and Native ads
- **API Endpoint**: `/ads-config` for Flutter app integration

### 2. App Updates Management
- **Version Control**: Manage app versions with force/normal update options
- **Platform Specific**: Support for Android, iOS, or both
- **Update Messages**: Custom messages for each update
- **Download Links**: Direct links to app stores or APK files
- **API Endpoint**: `/app-updates` for Flutter app integration

## Database Collections

### AdsConfig Collection
```javascript
{
  adType: String,        // banner, interstitial, rewarded, native
  adId: String,          // Ad unit ID (e.g., ca-app-pub-xxx)
  isActive: Boolean,     // Whether ad is active
  platform: String,     // android, ios, both
  description: String,   // Optional description
  createdAt: Date,
  updatedAt: Date
}
```

### AppUpdates Collection
```javascript
{
  versionName: String,    // e.g., "1.2.0"
  versionCode: Number,    // e.g., 12
  isForceUpdate: Boolean, // Force user to update
  isNormalUpdate: Boolean,// Show update dialog
  isActive: Boolean,      // Whether this version is active
  updateMessage: String,  // Message to show user
  updateLink: String,     // Download link
  platform: String,      // android, ios, both
  createdAt: Date,
  updatedAt: Date
}
```

## API Endpoints

### Ads Configuration
```
GET /ads-config?platform=android&key=YOUR_API_KEY
```

**Response:**
```json
{
  "success": true,
  "ads": [
    {
      "adType": "banner",
      "adId": "ca-app-pub-1234567890123456/1234567890",
      "platform": "android",
      "description": "Main banner ad"
    }
  ]
}
```

### App Updates
```
GET /app-updates?platform=android&key=YOUR_API_KEY
```

**Response:**
```json
{
  "success": true,
  "hasUpdate": true,
  "update": {
    "versionName": "1.2.0",
    "versionCode": 12,
    "isForceUpdate": false,
    "isNormalUpdate": true,
    "updateMessage": "New features and bug fixes available!",
    "updateLink": "https://play.google.com/store/apps/details?id=com.yourapp",
    "platform": "android"
  }
}
```

## Admin Panel Access

1. **Login**: http://localhost:3006
2. **Navigation**: 
   - Dashboard → Ads Management
   - Dashboard → App Updates

### Ads Management Features:
- Add/Update ad configurations
- Set ad types (Banner, Interstitial, Rewarded, Native)
- Platform-specific settings
- Activate/Deactivate ads
- View all current configurations

### App Updates Features:
- Create new app versions
- Set force/normal update flags
- Platform-specific updates
- Custom update messages
- Download links management
- Activate specific versions

## Flutter Integration

### 1. Ads Configuration
```dart
// Fetch ads configuration
final response = await http.get(
  Uri.parse('http://your-api-url/ads-config?platform=android&key=YOUR_API_KEY')
);

if (response.statusCode == 200) {
  final data = json.decode(response.body);
  if (data['success']) {
    // Use ads configuration
    final ads = data['ads'];
    // Initialize your ad networks with the received ad IDs
  }
}
```

### 2. App Updates Check
```dart
// Check for app updates
final response = await http.get(
  Uri.parse('http://your-api-url/app-updates?platform=android&key=YOUR_API_KEY')
);

if (response.statusCode == 200) {
  final data = json.decode(response.body);
  if (data['success'] && data['hasUpdate']) {
    final update = data['update'];
    
    if (update['isForceUpdate']) {
      // Show force update dialog
      showForceUpdateDialog(update);
    } else if (update['isNormalUpdate']) {
      // Show optional update dialog
      showUpdateDialog(update);
    }
  }
}
```

## Configuration

### Environment Variables
Make sure your `.env` file in the admin directory contains:
```
MONGODB_URI=mongodb+srv://turbomail:we1we2we3@turbomail.gjohjma.mongodb.net/?retryWrites=true&w=majority&appName=turbomail
```

### API Configuration
The API endpoints are automatically available once the mail-api server is running on port 3001.

## Security Notes

1. **API Key**: All endpoints require the master API key
2. **Input Validation**: Ad IDs are validated for proper format
3. **Platform Filtering**: Responses are filtered based on platform parameter
4. **MongoDB Security**: Uses MongoDB Atlas with authentication

## Deployment

1. **Admin Panel**: Runs on port 3006
2. **Mail API**: Runs on port 3001 with new endpoints
3. **Database**: MongoDB Atlas (cloud-hosted)
4. **Redis**: Required for email functionality

## Testing

1. Start the admin panel: `cd admin && node server.js`
2. Start the mail API: `cd mail-api && node index.js`
3. Access admin panel: http://localhost:3006
4. Test API endpoints: http://localhost:3001/ads-config?key=YOUR_API_KEY

## Support

For issues or questions regarding the ads and app updates functionality, check:
1. MongoDB Atlas connection
2. API key configuration
3. Admin panel logs
4. Mail API logs

---

**Note**: This integration maintains compatibility with existing TurboMail functionality while adding new features for mobile app management.