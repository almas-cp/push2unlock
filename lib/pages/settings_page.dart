import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<String> _popularApps = [
    'Instagram',
    'X',
    'YouTube',
    'Facebook',
    'TikTok',
    'Snapchat',
    'Reddit',
    'WhatsApp',
    'Telegram',
    'Discord',
    'LinkedIn',
    'Netflix',
    'Prime Video',
    'Disney+',
    'Spotify',
    'Twitter',
  ];
  List<String> _selectedApps = [];
  int _selectedRewardTime = 10;
  String _selectedExercise = 'Head Nods';
  int _selectedRepCount = 10;
  PermissionStatus _cameraPermissionStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkCameraPermission();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedApps = prefs.getStringList('selectedApps') ?? ['Instagram', 'X'];
      _selectedRewardTime = prefs.getInt('rewardTime') ?? 10;
      _selectedExercise = prefs.getString('exerciseType') ?? 'Head Nods';
      _selectedRepCount = prefs.getInt('repCount') ?? 10;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selectedApps', _selectedApps);
    await prefs.setInt('rewardTime', _selectedRewardTime);
    await prefs.setString('exerciseType', _selectedExercise);
    await prefs.setInt('repCount', _selectedRepCount);
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    setState(() {
      _cameraPermissionStatus = status;
    });
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _cameraPermissionStatus = status;
    });
  }

  void _showAddAppDialog() {
    final unselectedApps = _popularApps
        .where((app) => !_selectedApps.contains(app))
        .toList();

    showDialog(
      context: context,
      builder: (context) => _AddAppDialog(
        popularApps: unselectedApps,
        onAppSelected: (app) {
          setState(() {
            if (!_selectedApps.contains(app)) {
              _selectedApps.add(app);
            }
          });
          _saveSettings();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Monitored Apps Section
          _buildSectionHeader('Monitored Apps'),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ..._selectedApps.map((app) => CheckboxListTile(
                      title: Text(app),
                      value: true,
                      onChanged: (bool? value) {
                        if (value == false) {
                          setState(() {
                            _selectedApps.remove(app);
                          });
                          _saveSettings();
                        }
                      },
                      secondary: Icon(_getAppIcon(app)),
                    )),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Add New App'),
                  onTap: _showAddAppDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Reward Time Section
          _buildSectionHeader('Reward Time'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_selectedRewardTime minutes',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [5, 10, 15, 20, 25, 30].map((time) {
                      return ChoiceChip(
                        label: Text('$time min'),
                        selected: _selectedRewardTime == time,
                        onSelected: (selected) {
                          setState(() {
                            _selectedRewardTime = time;
                          });
                          _saveSettings();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Exercise Type Section
          _buildSectionHeader('Exercise Type'),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Head Nods'),
                  value: 'Head Nods',
                  groupValue: _selectedExercise,
                  onChanged: (value) {
                    setState(() {
                      _selectedExercise = value!;
                    });
                    _saveSettings();
                  },
                  secondary: const Icon(Icons.face),
                ),
                RadioListTile<String>(
                  title: const Text('Squats'),
                  value: 'Squats',
                  groupValue: _selectedExercise,
                  onChanged: (value) {
                    setState(() {
                      _selectedExercise = value!;
                    });
                    _saveSettings();
                  },
                  secondary: const Icon(Icons.accessibility_new),
                ),
                RadioListTile<String>(
                  title: const Text('Pushups'),
                  value: 'Pushups',
                  groupValue: _selectedExercise,
                  onChanged: (value) {
                    setState(() {
                      _selectedExercise = value!;
                    });
                    _saveSettings();
                  },
                  secondary: const Icon(Icons.fitness_center),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Exercise Rep Count Section
          _buildSectionHeader('Exercise Rep Count'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_selectedRepCount reps',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [5, 10, 15, 20].map((reps) {
                      return ChoiceChip(
                        label: Text('$reps reps'),
                        selected: _selectedRepCount == reps,
                        onSelected: (selected) {
                          setState(() {
                            _selectedRepCount = reps;
                          });
                          _saveSettings();
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Camera Permissions Section
          _buildSectionHeader('Camera Permissions'),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                _cameraPermissionStatus.isGranted
                    ? Icons.check_circle
                    : Icons.warning,
                color: _cameraPermissionStatus.isGranted
                    ? Colors.green
                    : Colors.orange,
              ),
              title: const Text('Camera Access'),
              subtitle: Text(
                _cameraPermissionStatus.isGranted
                    ? 'Granted'
                    : 'Required for exercise tracking',
              ),
              trailing: _cameraPermissionStatus.isGranted
                  ? null
                  : ElevatedButton(
                      onPressed: _requestCameraPermission,
                      child: const Text('Grant'),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  IconData _getAppIcon(String appName) {
    switch (appName.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt;
      case 'x':
      case 'twitter':
        return Icons.close;
      case 'youtube':
        return Icons.play_circle_fill;
      case 'facebook':
        return Icons.thumb_up;
      case 'tiktok':
        return Icons.music_note;
      case 'snapchat':
        return Icons.camera;
      case 'reddit':
        return Icons.forum;
      case 'whatsapp':
      case 'telegram':
      case 'discord':
        return Icons.message;
      case 'linkedin':
        return Icons.work;
      case 'netflix':
      case 'prime video':
      case 'disney+':
        return Icons.movie;
      case 'spotify':
        return Icons.music_note;
      default:
        return Icons.apps;
    }
  }
}

class _AddAppDialog extends StatefulWidget {
  final List<String> popularApps;
  final Function(String) onAppSelected;

  const _AddAppDialog({
    required this.popularApps,
    required this.onAppSelected,
  });

  @override
  State<_AddAppDialog> createState() => _AddAppDialogState();
}

class _AddAppDialogState extends State<_AddAppDialog> {
  String _searchQuery = '';
  List<String> _filteredApps = [];
  final TextEditingController _customAppController = TextEditingController();
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    _filteredApps = widget.popularApps;
  }

  @override
  void dispose() {
    _customAppController.dispose();
    super.dispose();
  }

  void _filterApps(String query) {
    setState(() {
      _searchQuery = query;
      _filteredApps = widget.popularApps
          .where((app) => app.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _addCustomApp() {
    final appName = _customAppController.text.trim();
    if (appName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an app name')),
      );
      return;
    }
    widget.onAppSelected(appName);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add App'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Toggle buttons for Popular vs Custom
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Popular Apps'),
                  icon: Icon(Icons.apps),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Custom'),
                  icon: Icon(Icons.edit),
                ),
              ],
              selected: {_showCustomInput},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _showCustomInput = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Show either popular apps list or custom input
            if (!_showCustomInput) ...[
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search apps...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: _filterApps,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: _filteredApps.isEmpty
                    ? const Center(
                        child: Text('No apps found'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredApps.length,
                        itemBuilder: (context, index) {
                          final app = _filteredApps[index];
                          return ListTile(
                            leading: Icon(_getAppIcon(app)),
                            title: Text(app),
                            onTap: () {
                              widget.onAppSelected(app);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ] else ...[
              // Custom app input
              TextField(
                controller: _customAppController,
                decoration: const InputDecoration(
                  labelText: 'App Name',
                  hintText: 'e.g., Chrome, Gmail, etc.',
                  border: OutlineInputBorder(),
                  helperText: 'Enter the app name to monitor',
                ),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _addCustomApp(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addCustomApp,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Custom App'),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  IconData _getAppIcon(String appName) {
    switch (appName.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt;
      case 'x':
      case 'twitter':
        return Icons.close;
      case 'youtube':
        return Icons.play_circle_fill;
      case 'facebook':
        return Icons.thumb_up;
      case 'tiktok':
        return Icons.music_note;
      case 'snapchat':
        return Icons.camera;
      case 'reddit':
        return Icons.forum;
      case 'whatsapp':
      case 'telegram':
      case 'discord':
        return Icons.message;
      case 'linkedin':
        return Icons.work;
      case 'netflix':
      case 'prime video':
      case 'disney+':
        return Icons.movie;
      case 'spotify':
        return Icons.music_note;
      default:
        return Icons.apps;
    }
  }
}
