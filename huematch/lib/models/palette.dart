class Palette {
  final int? id;
  final String name;
  final List<int> colorIds;
  final DateTime createdAt;

  Palette({
    this.id,
    required this.name,
    List<int>? colorIds,
    DateTime? createdAt,
  })  : colorIds = colorIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'colorIds': colorIds.join(','),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Palette.fromMap(Map<String, dynamic> map) {
    final colorIdsStr = map['colorIds'] as String? ?? '';
    return Palette(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorIds: colorIdsStr.isEmpty
          ? []
          : colorIdsStr.split(',').map((e) => int.parse(e.trim())).toList(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Palette copyWith({
    int? id,
    String? name,
    List<int>? colorIds,
    DateTime? createdAt,
  }) {
    return Palette(
      id: id ?? this.id,
      name: name ?? this.name,
      colorIds: colorIds ?? List<int>.from(this.colorIds),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
