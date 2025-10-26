import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<String> _availableApps = ['Instagram', 'X', 'YouTube'];
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
    final unselectedApps = _availableApps
        .where((app) => !_selectedApps.contains(app))
        .toList();

    if (unselectedApps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All apps are already selected')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _AddAppDialog(
        availableApps: unselectedApps,
        onAppSelected: (app) {
          setState(() {
            _selectedApps.add(app);
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
        return Icons.close;
      case 'youtube':
        return Icons.play_circle_fill;
      default:
        return Icons.apps;
    }
  }
}

class _AddAppDialog extends StatefulWidget {
  final List<String> availableApps;
  final Function(String) onAppSelected;

  const _AddAppDialog({
    required this.availableApps,
    required this.onAppSelected,
  });

  @override
  State<_AddAppDialog> createState() => _AddAppDialogState();
}

class _AddAppDialogState extends State<_AddAppDialog> {
  String _searchQuery = '';
  List<String> _filteredApps = [];

  @override
  void initState() {
    super.initState();
    _filteredApps = widget.availableApps;
  }

  void _filterApps(String query) {
    setState(() {
      _searchQuery = query;
      _filteredApps = widget.availableApps
          .where((app) => app.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
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
                          title: Text(app),
                          onTap: () {
                            widget.onAppSelected(app);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
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
}
