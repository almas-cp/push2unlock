import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:flutter/services.dart';

class AppLockService {
  Timer? _monitoringTimer;
  String _lastCheckedApp = '';
  List<String> _monitoredApps = [];
  DateTime? _countdownEndTime;
  Function(String)? onAppBlocked;
  
  static const platform = MethodChannel('com.example.push2unlock/app_control');

  Future<void> startMonitoring() async {
    print('🔒 [AppLockService] Starting app lock monitoring...');
    
    // Check overlay permission
    final hasOverlay = await checkOverlayPermission();
    if (!hasOverlay) {
      print('⚠️ [AppLockService] Overlay permission NOT granted!');
      print('💡 [AppLockService] Requesting overlay permission...');
      await requestOverlayPermission();
      return;
    }
    print('✅ [AppLockService] Overlay permission granted!');
    
    await _loadSettings();
    
    _monitoringTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _checkForegroundApp();
    });
  }

  static Future<bool> checkOverlayPermission() async {
    try {
      final result = await platform.invokeMethod('checkOverlayPermission');
      return result as bool;
    } catch (e) {
      print('❌ Error checking overlay permission: $e');
      return false;
    }
  }

  static Future<void> requestOverlayPermission() async {
    try {
      await platform.invokeMethod('requestOverlayPermission');
    } catch (e) {
      print('❌ Error requesting overlay permission: $e');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load monitored apps
    final selectedApps = prefs.getStringList('selectedApps') ?? ['Instagram', 'X'];
    _monitoredApps = selectedApps.map((app) => app.toLowerCase()).toList();
    
    // Load countdown end time
    final endTimeMillis = prefs.getInt('countdownEndTime');
    if (endTimeMillis != null) {
      _countdownEndTime = DateTime.fromMillisecondsSinceEpoch(endTimeMillis);
      
      // Check if still valid
      if (!_countdownEndTime!.isAfter(DateTime.now())) {
        _countdownEndTime = null;
      }
    }
    
    print('🔒 [AppLockService] Monitoring apps: $_monitoredApps');
    print('🔒 [AppLockService] Countdown end time: $_countdownEndTime');
  }

  Future<void> _checkForegroundApp() async {
    try {
      // Reload settings every check to stay updated
      await _loadSettings();
      
      // Check if we have time remaining
      if (_countdownEndTime != null && DateTime.now().isBefore(_countdownEndTime!)) {
        // User has time, don't block
        _lastCheckedApp = '';
        return;
      }
      
      // Get current foreground app
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(seconds: 2));
      
      final usageStats = await UsageStats.queryUsageStats(startTime, now);
      
      if (usageStats == null || usageStats.isEmpty) {
        return;
      }

      // Sort by last time used
      usageStats.sort((a, b) {
        final aTime = int.tryParse(a.lastTimeUsed ?? '0') ?? 0;
        final bTime = int.tryParse(b.lastTimeUsed ?? '0') ?? 0;
        return bTime.compareTo(aTime);
      });

      final currentApp = usageStats.first;
      final packageName = (currentApp.packageName ?? '').toLowerCase();
      
      // Skip if it's our own app
      if (packageName.contains('push2unlock')) {
        _lastCheckedApp = '';
        return;
      }
      
      // Check if current app is in monitored list
      bool isMonitored = _isAppMonitored(packageName);
      
      if (isMonitored) {
        // Get app name from package
        String appName = _getAppNameFromPackage(packageName);
        
        // Always force our app to foreground when a monitored app is detected
        print('🚨 [AppLockService] Blocked app detected: $packageName');
        print('⏰ [AppLockService] No time remaining! Force opening Push2Unlock...');
        await _bringAppToForeground();
        
        // Trigger callback only once per app switch
        if (packageName != _lastCheckedApp) {
          _lastCheckedApp = packageName;
          if (onAppBlocked != null) {
            onAppBlocked!(appName);
          }
        }
      } else {
        // Reset when user switches to a non-monitored app
        _lastCheckedApp = '';
      }
    } catch (e) {
      print('❌ [AppLockService] Error checking foreground app: $e');
    }
  }

  bool _isAppMonitored(String packageName) {
    for (final monitoredApp in _monitoredApps) {
      final appLower = monitoredApp.toLowerCase();
      
      // Special handling for X (Twitter)
      if (appLower == 'x' || appLower == 'twitter') {
        if (packageName.contains('twitter') || packageName.contains('x.')) {
          return true;
        }
      }
      // Special handling for Instagram
      else if (appLower == 'instagram') {
        if (packageName.contains('instagram')) {
          return true;
        }
      }
      // Special handling for Facebook
      else if (appLower == 'facebook') {
        if (packageName.contains('facebook')) {
          return true;
        }
      }
      // Special handling for YouTube
      else if (appLower == 'youtube') {
        if (packageName.contains('youtube')) {
          return true;
        }
      }
      // Special handling for TikTok
      else if (appLower == 'tiktok') {
        if (packageName.contains('tiktok')) {
          return true;
        }
      }
      // Special handling for Snapchat
      else if (appLower == 'snapchat') {
        if (packageName.contains('snapchat')) {
          return true;
        }
      }
      // Generic matching for other apps
      else if (packageName.contains(appLower)) {
        return true;
      }
    }
    return false;
  }

  String _getAppNameFromPackage(String packageName) {
    if (packageName.contains('instagram')) return 'Instagram';
    if (packageName.contains('twitter') || packageName.contains('x.')) return 'X';
    if (packageName.contains('youtube')) return 'YouTube';
    if (packageName.contains('facebook')) return 'Facebook';
    if (packageName.contains('tiktok')) return 'TikTok';
    if (packageName.contains('snapchat')) return 'Snapchat';
    if (packageName.contains('reddit')) return 'Reddit';
    if (packageName.contains('whatsapp')) return 'WhatsApp';
    if (packageName.contains('telegram')) return 'Telegram';
    if (packageName.contains('discord')) return 'Discord';
    if (packageName.contains('linkedin')) return 'LinkedIn';
    if (packageName.contains('netflix')) return 'Netflix';
    if (packageName.contains('primevideo') || packageName.contains('amazon')) return 'Prime Video';
    if (packageName.contains('disney')) return 'Disney+';
    if (packageName.contains('spotify')) return 'Spotify';
    if (packageName.contains('chrome')) return 'Chrome';
    if (packageName.contains('gmail')) return 'Gmail';
    
    // Default: capitalize first letter of last segment
    final parts = packageName.split('.');
    if (parts.isNotEmpty) {
      return parts.last[0].toUpperCase() + parts.last.substring(1);
    }
    return 'Unknown App';
  }

  Future<void> _bringAppToForeground() async {
    try {
      await platform.invokeMethod('bringToForeground');
      print('✅ [AppLockService] Brought app to foreground');
    } catch (e) {
      print('❌ [AppLockService] Error bringing app to foreground: $e');
    }
  }

  void stopMonitoring() {
    print('🛑 [AppLockService] Stopping app lock monitoring...');
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _lastCheckedApp = '';
  }

  void dispose() {
    stopMonitoring();
  }
}
