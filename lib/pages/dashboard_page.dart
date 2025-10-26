import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';
import 'settings_page.dart';
import '../services/foreground_app_detector.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isServiceRunning = false;
  List<MonitoredApp> _monitoredApps = [];
  final ForegroundAppDetector _appDetector = ForegroundAppDetector();
  bool _hasUsagePermission = false;

  @override
  void initState() {
    super.initState();
    print('✅ Dashboard loaded successfully!');
    _loadMonitoredApps();
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

  Future<void> _loadMonitoredApps() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedApps = prefs.getStringList('selectedApps') ?? ['Instagram', 'X'];
    
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
    
    // Start or stop foreground app monitoring
    if (_isServiceRunning) {
      await _appDetector.startMonitoring();
    } else {
      _appDetector.stopMonitoring();
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

  @override
  void dispose() {
    _appDetector.dispose();
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
              _loadMonitoredApps();
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
              // Earn Scroll Time Button
              Card(
                child: InkWell(
                  onTap: () {
                    // TODO: Navigate to exercise page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Starting exercise...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.timer,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Earn Scroll Time',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete exercises to unlock your apps',
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
