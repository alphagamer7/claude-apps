class Note {
  final String id;
  final String audioPath;
  String transcription;
  String tags;
  final DateTime createdAt;
  final int durationSeconds;

  Note({
    required this.id,
    required this.audioPath,
    this.transcription = '',
    this.tags = '',
    required this.createdAt,
    this.durationSeconds = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'audioPath': audioPath,
      'transcription': transcription,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'durationSeconds': durationSeconds,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      audioPath: map['audioPath'] as String,
      transcription: (map['transcription'] as String?) ?? '',
      tags: (map['tags'] as String?) ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      durationSeconds: (map['durationSeconds'] as int?) ?? 0,
    );
  }

  Note copyWith({
    String? id,
    String? audioPath,
    String? transcription,
    String? tags,
    DateTime? createdAt,
    int? durationSeconds,
  }) {
    return Note(
      id: id ?? this.id,
      audioPath: audioPath ?? this.audioPath,
      transcription: transcription ?? this.transcription,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  List<String> get tagList {
    if (tags.trim().isEmpty) return [];
    return tags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
  }

  String get firstLine {
    if (transcription.trim().isEmpty) return 'No transcription';
    final lines = transcription.trim().split('\n');
    final first = lines.first;
    return first.length > 80 ? '${first.substring(0, 80)}...' : first;
  }

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
