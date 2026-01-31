import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storage;

  const SettingsScreen({super.key, required this.storage});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _washDuration;
  late double _dryDuration;
  late bool _notificationSound;

  @override
  void initState() {
    super.initState();
    _washDuration = widget.storage.getWashDuration().toDouble();
    _dryDuration = widget.storage.getDryDuration().toDouble();
    _notificationSound = widget.storage.getNotificationSound();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Wash Cycle'),
          const SizedBox(height: 8),
          _buildDurationSlider(
            value: _washDuration,
            min: 15,
            max: 90,
            color: const Color(0xFF03A9F4),
            onChanged: (val) {
              setState(() => _washDuration = val);
              widget.storage.setWashDuration(val.round());
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Dry Cycle'),
          const SizedBox(height: 8),
          _buildDurationSlider(
            value: _dryDuration,
            min: 20,
            max: 90,
            color: const Color(0xFFFF9800),
            onChanged: (val) {
              setState(() => _dryDuration = val);
              widget.storage.setDryDuration(val.round());
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Notifications'),
          const SizedBox(height: 8),
          Card(
            color: Colors.grey[900],
            child: SwitchListTile(
              title: const Text('Notification Sound'),
              subtitle: const Text('Play sound when cycle completes'),
              value: _notificationSound,
              activeTrackColor: const Color(0xFF03A9F4),
              onChanged: (val) {
                setState(() => _notificationSound = val);
                widget.storage.setNotificationSound(val);
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Data'),
          const SizedBox(height: 8),
          Card(
            color: Colors.grey[900],
            child: ListTile(
              leading: const Icon(Icons.restart_alt, color: Colors.redAccent),
              title: const Text('Reset Weekly Counter'),
              subtitle: Text(
                'Current count: ${widget.storage.getWeeklyCount()} loads',
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Reset Counter?'),
                    content: const Text(
                      'This will reset your weekly load counter to zero.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          widget.storage.resetWeeklyCount();
                          Navigator.pop(ctx);
                          setState(() {});
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey[400],
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildDurationSlider({
    required double value,
    required double min,
    required double max,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Duration'),
                Text(
                  '${value.round()} min',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round(),
              activeColor: color,
              inactiveColor: color.withValues(alpha: 0.2),
              label: '${value.round()} min',
              onChanged: onChanged,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${min.round()} min',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  '${max.round()} min',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
