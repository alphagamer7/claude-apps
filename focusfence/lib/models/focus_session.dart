class FocusSession {
  final int? id;
  final String appName;
  final int durationMinutes;
  final DateTime startTime;
  final DateTime? endTime;
  final bool completed;
  final DateTime createdAt;

  FocusSession({
    this.id,
    required this.appName,
    required this.durationMinutes,
    required this.startTime,
    this.endTime,
    this.completed = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appName': appName,
      'durationMinutes': durationMinutes,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'completed': completed ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id'] as int?,
      appName: map['appName'] as String,
      durationMinutes: map['durationMinutes'] as int,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null
          ? DateTime.parse(map['endTime'] as String)
          : null,
      completed: (map['completed'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  FocusSession copyWith({
    int? id,
    String? appName,
    int? durationMinutes,
    DateTime? startTime,
    DateTime? endTime,
    bool? completed,
    DateTime? createdAt,
  }) {
    return FocusSession(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
