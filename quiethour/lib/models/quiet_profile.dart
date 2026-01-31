import 'package:flutter/material.dart';

class QuietProfile {
  final int? id;
  final String name;
  final int iconCodePoint;
  final String iconFontFamily;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<bool> activeDays; // Mon=0 ... Sun=6
  final bool isEnabled;

  QuietProfile({
    this.id,
    required this.name,
    this.iconCodePoint = 0xe425, // Icons.nightlight_round
    this.iconFontFamily = 'MaterialIcons',
    required this.startTime,
    required this.endTime,
    required this.activeDays,
    this.isEnabled = true,
  });

  IconData get iconData => IconData(iconCodePoint, fontFamily: iconFontFamily);

  QuietProfile copyWith({
    int? id,
    String? name,
    int? iconCodePoint,
    String? iconFontFamily,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<bool>? activeDays,
    bool? isEnabled,
  }) {
    return QuietProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      activeDays: activeDays ?? List<bool>.from(this.activeDays),
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'activeDays': activeDays.map((d) => d ? '1' : '0').join(','),
      'isEnabled': isEnabled ? 1 : 0,
    };
  }

  factory QuietProfile.fromMap(Map<String, dynamic> map) {
    final daysParts = (map['activeDays'] as String).split(',');
    return QuietProfile(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconCodePoint: map['iconCodePoint'] as int,
      iconFontFamily: map['iconFontFamily'] as String,
      startTime: TimeOfDay(
        hour: map['startHour'] as int,
        minute: map['startMinute'] as int,
      ),
      endTime: TimeOfDay(
        hour: map['endHour'] as int,
        minute: map['endMinute'] as int,
      ),
      activeDays: daysParts.map((d) => d == '1').toList(),
      isEnabled: (map['isEnabled'] as int) == 1,
    );
  }

  /// Returns the next scheduled DateTime for this profile, or null if none.
  DateTime? get nextScheduledTime {
    if (!isEnabled) return null;
    if (!activeDays.contains(true)) return null;

    final now = DateTime.now();
    // DateTime weekday: 1=Mon ... 7=Sun. Our activeDays: 0=Mon ... 6=Sun.
    for (int i = 0; i < 7; i++) {
      final candidate = now.add(Duration(days: i));
      final dayIndex = candidate.weekday - 1; // Convert to 0=Mon
      if (!activeDays[dayIndex]) continue;

      final scheduled = DateTime(
        candidate.year,
        candidate.month,
        candidate.day,
        startTime.hour,
        startTime.minute,
      );
      if (scheduled.isAfter(now)) return scheduled;
    }
    // Wrap around to next week
    for (int i = 0; i < 7; i++) {
      final candidate = now.add(Duration(days: 7 + i));
      final dayIndex = candidate.weekday - 1;
      if (!activeDays[dayIndex]) continue;

      return DateTime(
        candidate.year,
        candidate.month,
        candidate.day,
        startTime.hour,
        startTime.minute,
      );
    }
    return null;
  }

  String get startTimeFormatted => _formatTime(startTime);
  String get endTimeFormatted => _formatTime(endTime);

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String get activeDaysSummary {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final active = <String>[];
    for (int i = 0; i < 7; i++) {
      if (activeDays[i]) active.add(labels[i]);
    }
    if (active.length == 7) return 'Every day';
    if (active.length == 5 &&
        activeDays[0] &&
        activeDays[1] &&
        activeDays[2] &&
        activeDays[3] &&
        activeDays[4]) {
      return 'Weekdays';
    }
    if (active.length == 2 && activeDays[5] && activeDays[6]) {
      return 'Weekends';
    }
    return active.join(', ');
  }
}
