class PackItem {
  final int? id;
  final String name;
  final String category;
  final bool isChecked;
  final int sortOrder;

  const PackItem({
    this.id,
    required this.name,
    required this.category,
    this.isChecked = false,
    this.sortOrder = 0,
  });

  PackItem copyWith({
    int? id,
    String? name,
    String? category,
    bool? isChecked,
    int? sortOrder,
  }) {
    return PackItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      isChecked: isChecked ?? this.isChecked,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'is_checked': isChecked ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  factory PackItem.fromMap(Map<String, dynamic> map) {
    return PackItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      isChecked: (map['is_checked'] as int?) == 1,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  static const List<String> categories = [
    'Essentials',
    'Clothing',
    'Toiletries',
    'Electronics',
    'Documents',
    'Other',
  ];
}
