import 'dart:convert';

class WheelSize {
  final String name;
  final double circumferenceMm;

  const WheelSize({required this.name, required this.circumferenceMm});

  static const WheelSize road700c =
      WheelSize(name: '700c', circumferenceMm: 2100);
  static const WheelSize gravel650b =
      WheelSize(name: '650b', circumferenceMm: 2000);
  static const WheelSize mtb26 =
      WheelSize(name: '26"', circumferenceMm: 1973);
  static const WheelSize mtb29 =
      WheelSize(name: '29"', circumferenceMm: 2288);

  static const List<WheelSize> presets = [road700c, gravel650b, mtb26, mtb29];

  static WheelSize? fromName(String name) {
    for (final ws in presets) {
      if (ws.name == name) return ws;
    }
    return null;
  }

  double get circumferenceMeters => circumferenceMm / 1000.0;
  double get diameterMm => circumferenceMm / 3.14159265;
  double get diameterInches => diameterMm / 25.4;
}

class Drivetrain {
  final String id;
  final String name;
  final List<int> chainrings;
  final List<int> cassette;
  final double wheelCircumferenceMm;
  final String wheelSizeName;
  final DateTime createdAt;

  Drivetrain({
    required this.id,
    required this.name,
    required this.chainrings,
    required this.cassette,
    required this.wheelCircumferenceMm,
    required this.wheelSizeName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get wheelCircumferenceMeters => wheelCircumferenceMm / 1000.0;
  double get wheelDiameterMm => wheelCircumferenceMm / 3.14159265;
  double get wheelDiameterInches => wheelDiameterMm / 25.4;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'chainrings': chainrings,
        'cassette': cassette,
        'wheelCircumferenceMm': wheelCircumferenceMm,
        'wheelSizeName': wheelSizeName,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Drivetrain.fromJson(Map<String, dynamic> json) => Drivetrain(
        id: json['id'] as String,
        name: json['name'] as String,
        chainrings:
            (json['chainrings'] as List<dynamic>).map((e) => e as int).toList(),
        cassette:
            (json['cassette'] as List<dynamic>).map((e) => e as int).toList(),
        wheelCircumferenceMm:
            (json['wheelCircumferenceMm'] as num).toDouble(),
        wheelSizeName: json['wheelSizeName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String toJsonString() => jsonEncode(toJson());

  factory Drivetrain.fromJsonString(String jsonString) =>
      Drivetrain.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  // Common presets
  static Drivetrain roadPreset() => Drivetrain(
        id: 'preset_road',
        name: 'Road (50/34 + 11-28)',
        chainrings: [50, 34],
        cassette: [11, 12, 13, 14, 15, 17, 19, 21, 24, 28],
        wheelCircumferenceMm: 2100,
        wheelSizeName: '700c',
      );

  static Drivetrain gravelPreset() => Drivetrain(
        id: 'preset_gravel',
        name: 'Gravel (46/30 + 11-34)',
        chainrings: [46, 30],
        cassette: [11, 13, 15, 17, 19, 21, 24, 28, 32, 34],
        wheelCircumferenceMm: 2100,
        wheelSizeName: '700c',
      );

  static Drivetrain mtbPreset() => Drivetrain(
        id: 'preset_mtb',
        name: 'MTB (32 + 10-52)',
        chainrings: [32],
        cassette: [10, 12, 14, 16, 18, 21, 24, 28, 33, 39, 45, 52],
        wheelCircumferenceMm: 2288,
        wheelSizeName: '29"',
      );

  static List<Drivetrain> get presets =>
      [roadPreset(), gravelPreset(), mtbPreset()];
}
