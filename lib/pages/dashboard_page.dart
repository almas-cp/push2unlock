import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';
import 'settings_page.dart';
import 'exercise_page.dart';
import 'blocked_app_page.dart';
import '../services/foreground_app_detector.dart';
import '../services/app_lock_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isServiceRunning = false;
  List<MonitoredApp> _monitoredApps = [];
  final ForegroundAppDetector _appDetector = ForegroundAppDetector();
  final AppLockService _appLockService = AppLockService();
  bool _hasUsagePermission = false;
  
  // Countdown timer state
  DateTime? _countdownEndTime;
  Timer? _countdownTimer;
  String _exerciseType = 'Head Nods';
  int _repCount = 10;
  int _rewardTime = 10;

  @override
  void initState() {
    super.initState();
    print('✅ Dashboard loaded successfully!');
    _loadInitialData();
    _checkUsagePermission();
  }

  Future<void> _checkUsagePermission() async {
    final hasPermission = await UsageStats.checkUsagePermission();
    print('🔍 Usage permission check result: $hasPermission');
    setState(() {
      _hasUsagePermission = hasPermission ?? false;
    });
    print('📋 Permission state updated: $_hasUsagePermission');
  }

  // Load initial data including remaining time and countdown
  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedApps = prefs.getStringList('selectedApps') ?? ['Instagram', 'X'];
    
    // Load settings
    _exerciseType = prefs.getString('exerciseType') ?? 'Head Nods';
    _repCount = prefs.getInt('repCount') ?? 10;
    _rewardTime = prefs.getInt('rewardTime') ?? 10;
    
    // Load countdown end time
    final endTimeMillis = prefs.getInt('countdownEndTime');
    if (endTimeMillis != null) {
      _countdownEndTime = DateTime.fromMillisecondsSinceEpoch(endTimeMillis);
      
      // Check if countdown is still valid
      if (_countdownEndTime!.isAfter(DateTime.now())) {
        _startCountdown();
      } else {
        // Countdown expired, clear it
        _countdownEndTime = null;
        await prefs.remove('countdownEndTime');
      }
    }
    
    setState(() {
      _monitoredApps = selectedApps
          .map((name) => MonitoredApp(
                name: name,
                icon: _getAppIcon(name),
                timeRemaining: 0,
              ))
          .toList();
    });
  }

  // Reload only settings and apps list (not remaining time)
  Future<void> _reloadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedApps = prefs.getStringList('selectedApps') ?? ['Instagram', 'X'];
    
    // Load settings (but NOT remaining time)
    _exerciseType = prefs.getString('exerciseType') ?? 'Head Nods';
    _repCount = prefs.getInt('repCount') ?? 10;
    _rewardTime = prefs.getInt('rewardTime') ?? 10;
    
    setState(() {
      _monitoredApps = selectedApps
          .map((name) => MonitoredApp(
                name: name,
                icon: _getAppIcon(name),
                timeRemaining: 0,
              ))
          .toList();
    });
  }

  IconData _getAppIcon(String appName) {
    switch (appName.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt;
      case 'x':
        return Icons.close;
      case 'youtube':
        return Icons.play_circle_fill;
      default:
        return Icons.apps;
    }
  }

  Future<void> _toggleService() async {
    print('🔘 Start/Stop button pressed! Current state: ${_isServiceRunning ? "Running" : "Stopped"}');
    print('📊 Has usage permission: $_hasUsagePermission');
    
    if (!_isServiceRunning && !_hasUsagePermission) {
      // Permission not granted, show dialog
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚠️ Permission Required'),
          content: const Text(
            'Usage Stats permission is required to monitor foreground apps.\n\n'
            'Please grant the permission in Settings to enable monitoring.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      );
      
      if (shouldRequest == true) {
        await UsageStats.grantUsagePermission();
        await _checkUsagePermission();
      }
      return;
    }
    
    setState(() {
      _isServiceRunning = !_isServiceRunning;
    });
    
    // Start or stop foreground app monitoring and app lock
    if (_isServiceRunning) {
      await _appDetector.startMonitoring();
      
      // Set up callback for when app is blocked
      _appLockService.onAppBlocked = (appName) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlockedAppPage(appName: appName),
            ),
          );
        }
      };
      
      await _appLockService.startMonitoring();
    } else {
      _appDetector.stopMonitoring();
      _appLockService.stopMonitoring();
    }
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isServiceRunning
              ? '✅ Monitoring started - Check terminal logs!'
              : '⏸️ Monitoring stopped',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _startExercise() async {
    print('🏋️ Starting exercise: $_exerciseType');
    
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => ExercisePage(
          exerciseType: _exerciseType,
          repCount: _repCount,
          rewardTime: _rewardTime,
        ),
      ),
    );

    if (result != null && result > 0) {
      print('🎉 Exercise completed! Reward: $result minutes');
      
      // Calculate end time based on current time + reward minutes
      final endTime = DateTime.now().add(Duration(minutes: result));
      
      setState(() {
        _countdownEndTime = endTime;
      });
      
      await _saveCountdownEndTime();
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownEndTime == null || DateTime.now().isAfter(_countdownEndTime!)) {
        // Countdown finished
        setState(() {
          _countdownEndTime = null;
        });
        _countdownTimer?.cancel();
        _clearCountdownEndTime();
      } else {
        // Just trigger a rebuild to update the display
        setState(() {});
      }
    });
  }

  Future<void> _saveCountdownEndTime() async {
    if (_countdownEndTime != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('countdownEndTime', _countdownEndTime!.millisecondsSinceEpoch);
    }
  }

  Future<void> _clearCountdownEndTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('countdownEndTime');
  }

  int _getRemainingSeconds() {
    if (_countdownEndTime == null) return 0;
    final remaining = _countdownEndTime!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  String _formatTime() {
    final seconds = _getRemainingSeconds();
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _appDetector.dispose();
    _appLockService.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Push2Unlock',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
              _reloadSettings();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Earn Scroll Time Button or Countdown Timer
              Card(
                child: InkWell(
                  onTap: _countdownEndTime != null ? null : _startExercise,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _countdownEndTime != null
                                ? Colors.green
                                : Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _countdownEndTime != null ? Icons.check_circle : Icons.fitness_center,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _countdownEndTime != null
                              ? _formatTime()
                              : 'Earn Scroll Time',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: _countdownEndTime != null ? 36 : null,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _countdownEndTime != null
                              ? 'Time remaining for apps'
                              : 'Complete exercises to unlock your apps',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Monitored Apps Header
              Text(
                'Monitored Apps',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              // Monitored Apps List
              Expanded(
                child: _monitoredApps.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.apps_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No apps selected',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Go to settings to add apps',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _monitoredApps.length,
                        itemBuilder: (context, index) {
                          final app = _monitoredApps[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: Icon(
                                  app.icon,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                app.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                app.timeRemaining > 0
                                    ? '${app.timeRemaining} min remaining'
                                    : 'No time remaining',
                              ),
                              trailing: Icon(
                                app.timeRemaining > 0
                                    ? Icons.lock_open
                                    : Icons.lock,
                                color: app.timeRemaining > 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleService,
        icon: Icon(_isServiceRunning ? Icons.pause : Icons.play_arrow),
        label: Text(_isServiceRunning ? 'Pause' : 'Start'),
        backgroundColor: _isServiceRunning
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class MonitoredApp {
  final String name;
  final IconData icon;
  final int timeRemaining;

  MonitoredApp({
    required this.name,
    required this.icon,
    required this.timeRemaining,
  });
}
