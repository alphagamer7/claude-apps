import 'pack_item.dart';

class Trip {
  final int? id;
  final String name;
  final int templateId;
  final List<PackItem> items;
  final DateTime createdAt;

  Trip({
    this.id,
    required this.name,
    required this.templateId,
    List<PackItem>? items,
    DateTime? createdAt,
  })  : items = items ?? [],
        createdAt = createdAt ?? DateTime.now();

  Trip copyWith({
    int? id,
    String? name,
    int? templateId,
    List<PackItem>? items,
    DateTime? createdAt,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      templateId: templateId ?? this.templateId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  int get checkedCount => items.where((i) => i.isChecked).length;
  int get totalCount => items.length;
  double get progress => totalCount > 0 ? checkedCount / totalCount : 0.0;
  bool get isFullyPacked => checkedCount == totalCount && totalCount > 0;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'template_id': templateId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map, {List<PackItem>? items}) {
    return Trip(
      id: map['id'] as int?,
      name: map['name'] as String,
      templateId: map['template_id'] as int,
      items: items ?? [],
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
