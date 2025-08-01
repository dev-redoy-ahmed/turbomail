import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'api_service.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  // Check for app updates
  Future<void> checkForUpdate([BuildContext? context]) async {
    try {
      if (Platform.isAndroid) {
        // Check for update availability
        final updateInfo = await InAppUpdate.checkForUpdate();
        
        if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable && context != null) {
          // Show update dialog
          _showUpdateDialog(context, updateInfo);
        }
      } else if (Platform.isIOS && context != null) {
        // For iOS, show a custom dialog to redirect to App Store
        _showIOSUpdateDialog(context);
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  // Public method to show update dialog
  Future<void> showUpdateDialog(BuildContext context) async {
    await checkForUpdate(context);
  }

  // Check for VPS-based app updates
  Future<void> checkForVPSUpdate(BuildContext context) async {
    try {
      debugPrint('🔄 Checking for VPS app updates...');
      
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;
      
      debugPrint('📱 Current app version: $currentVersion (build: $currentBuildNumber)');
      
      // Get app updates from VPS API
      final apiService = ApiService();
      final updates = await apiService.getAppUpdates();
      
      if (updates.isNotEmpty) {
        // Get the latest active update
        final latestUpdate = updates.firstWhere(
          (update) => update['is_active'] == true,
          orElse: () => {},
        );
        
        if (latestUpdate.isNotEmpty) {
          final latestVersionCode = latestUpdate['version_code'] as int;
          final latestVersionName = latestUpdate['version_name'] as String;
          final isForceUpdate = latestUpdate['is_force_update'] as bool;
          final updateMessage = latestUpdate['update_message'] as String;
          
          debugPrint('🆕 Latest version available: $latestVersionName (code: $latestVersionCode)');
          debugPrint('🔄 Force update: $isForceUpdate');
          
          // Check if update is needed
          if (latestVersionCode > currentBuildNumber) {
            debugPrint('✅ Update available! Showing update dialog...');
            _showVPSUpdateDialog(
              context,
              latestVersionName,
              updateMessage,
              isForceUpdate,
            );
          } else {
            debugPrint('✅ App is up to date');
          }
        } else {
          debugPrint('ℹ️ No active updates found');
        }
      } else {
        debugPrint('ℹ️ No updates available');
      }
    } catch (e) {
      debugPrint('❌ Error checking VPS updates: $e');
    }
  }

  // Show update dialog for Android
  void _showUpdateDialog(BuildContext context, AppUpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A2434),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.system_update,
                color: const Color(0xFF00D4AA),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'App Update Available',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A new version of TurboMail is available with exciting new features and improvements!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00D4AA).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: const Color(0xFF00D4AA),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Update now to get the latest features!',
                        style: TextStyle(
                          color: Color(0xFF00D4AA),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Later',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performUpdate(updateInfo);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4AA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Update Now',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show update dialog for iOS
  void _showIOSUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A2434),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.system_update,
                color: const Color(0xFF00D4AA),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'App Update Available',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A new version of TurboMail is available on the App Store with exciting new features!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4AA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00D4AA).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: const Color(0xFF00D4AA),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Visit App Store to update!',
                        style: TextStyle(
                          color: Color(0xFF00D4AA),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Later',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // You can implement App Store redirect here
                // launch('https://apps.apple.com/app/your-app-id');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4AA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Go to App Store',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Perform the update for Android
  Future<void> _performUpdate(AppUpdateInfo updateInfo) async {
    try {
      if (updateInfo.immediateUpdateAllowed) {
        // Perform immediate update
        await InAppUpdate.performImmediateUpdate();
      } else if (updateInfo.flexibleUpdateAllowed) {
        // Start flexible update
        await InAppUpdate.startFlexibleUpdate();
        
        // Listen for update download completion
        InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      debugPrint('Error performing update: $e');
    }
  }

  // Check for flexible update completion
  Future<void> checkFlexibleUpdateCompletion() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('Error completing flexible update: $e');
    }
  }

  // Show VPS update dialog
  void _showVPSUpdateDialog(
    BuildContext context,
    String latestVersion,
    String updateMessage,
    bool isForceUpdate,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate, // Can't dismiss if force update
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => !isForceUpdate, // Prevent back button if force update
          child: AlertDialog(
            backgroundColor: const Color(0xFF1A2434),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  isForceUpdate ? Icons.warning : Icons.system_update,
                  color: isForceUpdate ? Colors.orange : const Color(0xFF00D4AA),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isForceUpdate ? 'Required Update' : 'App Update Available',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isForceUpdate
                      ? 'A critical update is required to continue using TurboMail.'
                      : 'A new version of TurboMail is available!',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4AA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF00D4AA).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.new_releases,
                            color: const Color(0xFF00D4AA),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Version $latestVersion',
                            style: const TextStyle(
                              color: Color(0xFF00D4AA),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        updateMessage,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (!isForceUpdate)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Later',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Here you can implement the update logic
                  // For now, we'll show a message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please update from Google Play Store or App Store'),
                      backgroundColor: const Color(0xFF00D4AA),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isForceUpdate ? Colors.orange : const Color(0xFF00D4AA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isForceUpdate ? 'Update Now' : 'Update',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}