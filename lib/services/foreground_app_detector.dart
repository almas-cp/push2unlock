import 'dart:async';
import 'package:usage_stats/usage_stats.dart';

class ForegroundAppDetector {
  Timer? _timer;
  String _lastApp = '';
  
  // Emoji map for different apps
  final Map<String, String> _appEmojis = {
    'instagram': '📷',
    'facebook': '👍',
    'twitter': '🐦',
    'x': '❌',
    'youtube': '📺',
    'whatsapp': '💬',
    'chrome': '🌐',
    'gmail': '📧',
    'maps': '🗺️',
    'photos': '🖼️',
    'camera': '📸',
    'settings': '⚙️',
    'phone': '📞',
    'messages': '💬',
    'clock': '⏰',
    'calendar': '📅',
    'tiktok': '🎵',
    'snapchat': '👻',
    'spotify': '🎧',
    'netflix': '🎬',
    'amazon': '🛒',
    'reddit': '🤖',
    'telegram': '✈️',
    'discord': '💬',
    'messenger': '💬',
    'linkedin': '💼',
    'uber': '🚗',
    'default': '📱',
  };

  Future<void> startMonitoring() async {
    print('🚀 [ForegroundAppDetector] Starting foreground app monitoring...');
    
    // Check if we have usage stats permission
    final hasPermission = await UsageStats.checkUsagePermission();
    
    if (hasPermission != true) {
      print('❌ [ForegroundAppDetector] Usage stats permission NOT granted!');
      print('⚠️ [ForegroundAppDetector] Please grant usage stats permission in Settings');
      print('   [ForegroundAppDetector] Go to: Settings > Apps > Special access > Usage access');
      return;
    }
    
    print('✅ [ForegroundAppDetector] Usage stats permission granted!');
    print('👀 [ForegroundAppDetector] Monitoring foreground apps...');
    
    // Check immediately
    await _checkForegroundApp();
    
    // Then check every 2 seconds
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _checkForegroundApp();
    });
  }

  void stopMonitoring() {
    print('🛑 [ForegroundAppDetector] Stopping foreground app monitoring...');
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkForegroundApp() async {
    try {
      // Get current time
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(minutes: 1));
      
      // Query usage stats for the last minute
      final usageStats = await UsageStats.queryUsageStats(
        startTime,
        now,
      );

      if (usageStats == null) {
        print('⚠️ [ForegroundAppDetector] UsageStats returned null - permission may not be granted');
        return;
      }

      if (usageStats.isEmpty) {
        print('⚠️ [ForegroundAppDetector] No usage stats found');
        return;
      }

      // Sort by last time used (most recent first)
      usageStats.sort((a, b) {
        final aTime = int.tryParse(a.lastTimeUsed ?? '0') ?? 0;
        final bTime = int.tryParse(b.lastTimeUsed ?? '0') ?? 0;
        return bTime.compareTo(aTime);
      });

      // Get the most recently used app
      final currentApp = usageStats.first;
      final packageName = currentApp.packageName ?? 'unknown';
      final appName = _getAppName(packageName);
      
      // Debug: Always log current app to see what's happening
      print('🔍 [ForegroundAppDetector] Current app: $packageName');
      
      // Only log full details if app changed
      if (packageName != _lastApp) {
        _lastApp = packageName;
        final emoji = _getEmoji(packageName);
        
        print('');
        print('$emoji━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$emoji');
        print('$emoji FOREGROUND APP CHANGED $emoji');
        print('📱 App Name: $appName');
        print('📦 Package: $packageName');
        print('⏰ Time: ${DateTime.now().toString().substring(11, 19)}');
        print('$emoji━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$emoji');
        print('');
      }
    } catch (e, stackTrace) {
      print('❌ [ForegroundAppDetector] Error detecting foreground app: $e');
      print('Stack trace: $stackTrace');
    }
  }

  String _getAppName(String packageName) {
    // Extract app name from package name
    final parts = packageName.split('.');
    if (parts.isNotEmpty) {
      return parts.last.toUpperCase();
    }
    return packageName.toUpperCase();
  }

  String _getEmoji(String packageName) {
    final lowerPackage = packageName.toLowerCase();
    
    for (final entry in _appEmojis.entries) {
      if (lowerPackage.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return _appEmojis['default']!;
  }

  void dispose() {
    stopMonitoring();
  }
}
