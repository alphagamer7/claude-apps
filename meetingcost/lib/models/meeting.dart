class Meeting {
  final int? id;
  final int attendeeCount;
  final double hourlyRate;
  final int durationSeconds;
  final double totalCost;
  final bool isPaused;
  final DateTime createdAt;
  final String note;

  Meeting({
    this.id,
    required this.attendeeCount,
    required this.hourlyRate,
    required this.durationSeconds,
    required this.totalCost,
    this.isPaused = false,
    DateTime? createdAt,
    this.note = '',
  }) : createdAt = createdAt ?? DateTime.now();

  double get costPerPerson => attendeeCount > 0 ? totalCost / attendeeCount : 0;
  double get costPerMinute =>
      durationSeconds > 0 ? totalCost / (durationSeconds / 60) : 0;

  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'attendeeCount': attendeeCount,
      'hourlyRate': hourlyRate,
      'durationSeconds': durationSeconds,
      'totalCost': totalCost,
      'isPaused': isPaused ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'note': note,
    };
  }

  factory Meeting.fromMap(Map<String, dynamic> map) {
    return Meeting(
      id: map['id'] as int?,
      attendeeCount: map['attendeeCount'] as int,
      hourlyRate: (map['hourlyRate'] as num).toDouble(),
      durationSeconds: map['durationSeconds'] as int,
      totalCost: (map['totalCost'] as num).toDouble(),
      isPaused: (map['isPaused'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      note: (map['note'] as String?) ?? '',
    );
  }

  Meeting copyWith({
    int? id,
    int? attendeeCount,
    double? hourlyRate,
    int? durationSeconds,
    double? totalCost,
    bool? isPaused,
    DateTime? createdAt,
    String? note,
  }) {
    return Meeting(
      id: id ?? this.id,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      totalCost: totalCost ?? this.totalCost,
      isPaused: isPaused ?? this.isPaused,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }
}
