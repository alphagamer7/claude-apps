class SavedColor {
  final int? id;
  final String hex;
  final int red;
  final int green;
  final int blue;
  final double hue;
  final double saturation;
  final double lightness;
  final String nearestName;
  final String? paletteName;
  final DateTime createdAt;

  SavedColor({
    this.id,
    required this.hex,
    required this.red,
    required this.green,
    required this.blue,
    required this.hue,
    required this.saturation,
    required this.lightness,
    required this.nearestName,
    this.paletteName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'hex': hex,
      'red': red,
      'green': green,
      'blue': blue,
      'hue': hue,
      'saturation': saturation,
      'lightness': lightness,
      'nearestName': nearestName,
      'paletteName': paletteName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavedColor.fromMap(Map<String, dynamic> map) {
    return SavedColor(
      id: map['id'] as int?,
      hex: map['hex'] as String,
      red: map['red'] as int,
      green: map['green'] as int,
      blue: map['blue'] as int,
      hue: (map['hue'] as num).toDouble(),
      saturation: (map['saturation'] as num).toDouble(),
      lightness: (map['lightness'] as num).toDouble(),
      nearestName: map['nearestName'] as String,
      paletteName: map['paletteName'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  SavedColor copyWith({
    int? id,
    String? hex,
    int? red,
    int? green,
    int? blue,
    double? hue,
    double? saturation,
    double? lightness,
    String? nearestName,
    String? paletteName,
    DateTime? createdAt,
  }) {
    return SavedColor(
      id: id ?? this.id,
      hex: hex ?? this.hex,
      red: red ?? this.red,
      green: green ?? this.green,
      blue: blue ?? this.blue,
      hue: hue ?? this.hue,
      saturation: saturation ?? this.saturation,
      lightness: lightness ?? this.lightness,
      nearestName: nearestName ?? this.nearestName,
      paletteName: paletteName ?? this.paletteName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
