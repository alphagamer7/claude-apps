import 'dart:convert';
import 'dart:math' as math;

class LineSegment {
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double? realDimensionMm;
  final bool isReference;

  LineSegment({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    this.realDimensionMm,
    this.isReference = false,
  });

  double get pixelLength {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return math.sqrt(dx * dx + dy * dy);
  }

  Map<String, dynamic> toJson() => {
        'x1': x1,
        'y1': y1,
        'x2': x2,
        'y2': y2,
        'realDimensionMm': realDimensionMm,
        'isReference': isReference,
      };

  factory LineSegment.fromJson(Map<String, dynamic> json) => LineSegment(
        x1: (json['x1'] as num).toDouble(),
        y1: (json['y1'] as num).toDouble(),
        x2: (json['x2'] as num).toDouble(),
        y2: (json['y2'] as num).toDouble(),
        realDimensionMm: json['realDimensionMm'] != null
            ? (json['realDimensionMm'] as num).toDouble()
            : null,
        isReference: json['isReference'] as bool? ?? false,
      );
}

class Measurement {
  final int? id;
  final String imagePath;
  final String referenceType;
  final List<LineSegment> lines;
  final String unit;
  final DateTime createdAt;
  final String? note;

  Measurement({
    this.id,
    required this.imagePath,
    required this.referenceType,
    required this.lines,
    this.unit = 'cm',
    DateTime? createdAt,
    this.note,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'imagePath': imagePath,
        'referenceType': referenceType,
        'measurements': jsonEncode(lines.map((l) => l.toJson()).toList()),
        'unit': unit,
        'createdAt': createdAt.toIso8601String(),
        'note': note,
      };

  factory Measurement.fromMap(Map<String, dynamic> map) {
    final linesJson = jsonDecode(map['measurements'] as String) as List;
    return Measurement(
      id: map['id'] as int?,
      imagePath: map['imagePath'] as String,
      referenceType: map['referenceType'] as String,
      lines: linesJson
          .map((e) => LineSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
      unit: map['unit'] as String? ?? 'cm',
      createdAt: DateTime.parse(map['createdAt'] as String),
      note: map['note'] as String?,
    );
  }

  Measurement copyWith({
    int? id,
    String? imagePath,
    String? referenceType,
    List<LineSegment>? lines,
    String? unit,
    DateTime? createdAt,
    String? note,
  }) =>
      Measurement(
        id: id ?? this.id,
        imagePath: imagePath ?? this.imagePath,
        referenceType: referenceType ?? this.referenceType,
        lines: lines ?? this.lines,
        unit: unit ?? this.unit,
        createdAt: createdAt ?? this.createdAt,
        note: note ?? this.note,
      );
}
