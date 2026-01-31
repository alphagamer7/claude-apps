import 'dart:convert';

class Artwork {
  final int? id;
  final String name;
  final int gridSize;
  final int paletteIndex;
  final List<int> gridData;
  final DateTime createdAt;
  final DateTime updatedAt;

  Artwork({
    this.id,
    required this.name,
    required this.gridSize,
    required this.paletteIndex,
    List<int>? gridData,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : gridData = gridData ?? List.filled(gridSize * gridSize, -1),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Artwork copyWith({
    int? id,
    String? name,
    int? gridSize,
    int? paletteIndex,
    List<int>? gridData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Artwork(
      id: id ?? this.id,
      name: name ?? this.name,
      gridSize: gridSize ?? this.gridSize,
      paletteIndex: paletteIndex ?? this.paletteIndex,
      gridData: gridData ?? List<int>.from(this.gridData),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'gridSize': gridSize,
      'paletteIndex': paletteIndex,
      'gridData': jsonEncode(gridData),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Artwork.fromMap(Map<String, dynamic> map) {
    final List<dynamic> decoded = jsonDecode(map['gridData'] as String);
    return Artwork(
      id: map['id'] as int?,
      name: map['name'] as String,
      gridSize: map['gridSize'] as int,
      paletteIndex: map['paletteIndex'] as int,
      gridData: decoded.cast<int>(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  int getCell(int row, int col) {
    if (row < 0 || row >= gridSize || col < 0 || col >= gridSize) return -1;
    return gridData[row * gridSize + col];
  }

  Artwork setCell(int row, int col, int colorIndex) {
    if (row < 0 || row >= gridSize || col < 0 || col >= gridSize) return this;
    final newData = List<int>.from(gridData);
    newData[row * gridSize + col] = colorIndex;
    return copyWith(gridData: newData, updatedAt: DateTime.now());
  }
}
