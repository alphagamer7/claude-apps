class Counter {
  final int? id;
  final String name;
  final int color;
  int currentValue;
  final bool dailyReset;
  final DateTime createdAt;
  int sortOrder;

  Counter({
    this.id,
    required this.name,
    required this.color,
    this.currentValue = 0,
    this.dailyReset = false,
    DateTime? createdAt,
    this.sortOrder = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color': color,
      'currentValue': currentValue,
      'dailyReset': dailyReset ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'sortOrder': sortOrder,
    };
  }

  factory Counter.fromMap(Map<String, dynamic> map) {
    return Counter(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: map['color'] as int,
      currentValue: map['currentValue'] as int? ?? 0,
      dailyReset: (map['dailyReset'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      sortOrder: map['sortOrder'] as int? ?? 0,
    );
  }

  Counter copyWith({
    int? id,
    String? name,
    int? color,
    int? currentValue,
    bool? dailyReset,
    DateTime? createdAt,
    int? sortOrder,
  }) {
    return Counter(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      currentValue: currentValue ?? this.currentValue,
      dailyReset: dailyReset ?? this.dailyReset,
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
