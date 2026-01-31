import 'package:flutter/material.dart';
import '../models/quiet_profile.dart';
import '../services/database_service.dart';
import '../widgets/day_selector.dart';

class ProfileEditorScreen extends StatefulWidget {
  final QuietProfile? profile;

  const ProfileEditorScreen({super.key, this.profile});

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late List<bool> _activeDays;
  late bool _isEnabled;
  late int _selectedIconCodePoint;

  bool get _isEditing => widget.profile != null;

  static const List<IconData> _availableIcons = [
    Icons.nightlight_round,
    Icons.bedtime,
    Icons.work,
    Icons.school,
    Icons.movie,
    Icons.restaurant,
    Icons.fitness_center,
    Icons.self_improvement,
    Icons.menu_book,
    Icons.music_off,
    Icons.meeting_room,
    Icons.flight,
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.profile!;
      _nameController.text = p.name;
      _startTime = p.startTime;
      _endTime = p.endTime;
      _activeDays = List<bool>.from(p.activeDays);
      _isEnabled = p.isEnabled;
      _selectedIconCodePoint = p.iconCodePoint;
    } else {
      _startTime = const TimeOfDay(hour: 22, minute: 0);
      _endTime = const TimeOfDay(hour: 7, minute: 0);
      _activeDays = List.filled(7, true);
      _isEnabled = true;
      _selectedIconCodePoint = Icons.nightlight_round.codePoint;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.grey[900],
              dialHandColor: const Color(0xFF7C4DFF),
              hourMinuteColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? const Color(0xFF7C4DFF)
                      : Colors.grey[800]!),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? Colors.white
                      : Colors.grey[400]!),
              dayPeriodColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? const Color(0xFF7C4DFF)
                      : Colors.grey[800]!),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_activeDays.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one day'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final profile = QuietProfile(
      id: widget.profile?.id,
      name: _nameController.text.trim(),
      iconCodePoint: _selectedIconCodePoint,
      iconFontFamily: 'MaterialIcons',
      startTime: _startTime,
      endTime: _endTime,
      activeDays: _activeDays,
      isEnabled: _isEnabled,
    );

    if (_isEditing) {
      await _dbService.updateProfile(profile);
    } else {
      await _dbService.insertProfile(profile);
    }

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Profile',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${widget.profile!.name}"?',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbService.deleteProfile(widget.profile!.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Icon',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableIcons.map((icon) {
                final isSelected = icon.codePoint == _selectedIconCodePoint;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedIconCodePoint = icon.codePoint);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF7C4DFF)
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: const Color(0xFF7C4DFF), width: 2)
                          : null,
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : Colors.grey[400],
                      size: 26,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Profile' : 'New Profile'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Icon and name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _showIconPicker,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      IconData(_selectedIconCodePoint,
                          fontFamily: 'MaterialIcons'),
                      color: const Color(0xFF7C4DFF),
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: 'Profile Name',
                      labelStyle: TextStyle(color: Colors.grey[500]),
                      hintText: 'e.g., Bedtime, Meeting, Focus',
                      hintStyle: TextStyle(color: Colors.grey[700]),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[800]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFF7C4DFF)),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      filled: true,
                      fillColor: Colors.grey[900],
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Time section
            const Text(
              'Schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTimePicker('Start', _startTime, true)),
                const SizedBox(width: 16),
                Expanded(child: _buildTimePicker('End', _endTime, false)),
              ],
            ),
            const SizedBox(height: 32),

            // Day selector
            const Text(
              'Active Days',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select which days this profile should be active',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            DaySelector(
              selectedDays: _activeDays,
              onChanged: (days) => setState(() => _activeDays = days),
            ),
            const SizedBox(height: 8),
            // Quick select buttons
            Row(
              children: [
                _buildQuickDayButton('Weekdays', () {
                  setState(() {
                    _activeDays = [
                      true, true, true, true, true, false, false
                    ];
                  });
                }),
                const SizedBox(width: 8),
                _buildQuickDayButton('Weekends', () {
                  setState(() {
                    _activeDays = [
                      false, false, false, false, false, true, true
                    ];
                  });
                }),
                const SizedBox(width: 8),
                _buildQuickDayButton('Every day', () {
                  setState(() {
                    _activeDays = List.filled(7, true);
                  });
                }),
              ],
            ),
            const SizedBox(height: 32),

            // Enable toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Enable Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  _isEnabled
                      ? 'This profile will activate on schedule'
                      : 'This profile is currently disabled',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                value: _isEnabled,
                onChanged: (value) => setState(() => _isEnabled = value),
                activeTrackColor: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
                activeThumbColor: const Color(0xFF7C4DFF),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(_isEditing ? 'Save Changes' : 'Create Profile'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, bool isStart) {
    return GestureDetector(
      onTap: () => _pickTime(isStart),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  isStart ? Icons.play_arrow_rounded : Icons.stop_rounded,
                  color: const Color(0xFF7C4DFF),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(time),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDayButton(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF7C4DFF),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
