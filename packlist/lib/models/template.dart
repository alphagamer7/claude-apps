import 'pack_item.dart';

class Template {
  final int? id;
  final String name;
  final String iconName;
  final List<PackItem> items;
  final DateTime createdAt;
  final bool isDefault;

  Template({
    this.id,
    required this.name,
    this.iconName = 'luggage',
    List<PackItem>? items,
    DateTime? createdAt,
    this.isDefault = false,
  })  : items = items ?? [],
        createdAt = createdAt ?? DateTime.now();

  Template copyWith({
    int? id,
    String? name,
    String? iconName,
    List<PackItem>? items,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return Template(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon_name': iconName,
      'created_at': createdAt.toIso8601String(),
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory Template.fromMap(Map<String, dynamic> map, {List<PackItem>? items}) {
    return Template(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconName: map['icon_name'] as String? ?? 'luggage',
      items: items ?? [],
      createdAt: DateTime.parse(map['created_at'] as String),
      isDefault: (map['is_default'] as int?) == 1,
    );
  }
}
