class ShelfItem {
  final int? id;
  final String name;
  final String category;
  final DateTime openedDate;
  final int shelfLifeDays;
  final bool notified;
  final String status; // 'active', 'used', 'discarded'
  final DateTime createdAt;

  ShelfItem({
    this.id,
    required this.name,
    required this.category,
    required this.openedDate,
    required this.shelfLifeDays,
    this.notified = false,
    this.status = 'active',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  DateTime get expiryDate => openedDate.add(Duration(days: shelfLifeDays));

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  double get percentRemaining {
    if (shelfLifeDays == 0) return 0.0;
    final remaining = daysRemaining;
    if (remaining <= 0) return 0.0;
    return (remaining / shelfLifeDays).clamp(0.0, 1.0);
  }

  bool get isExpired => daysRemaining < 0;
  bool get isExpiringSoon => daysRemaining >= 0 && percentRemaining <= 0.25;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'openedDate': openedDate.toIso8601String(),
      'shelfLifeDays': shelfLifeDays,
      'notified': notified ? 1 : 0,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ShelfItem.fromMap(Map<String, dynamic> map) {
    return ShelfItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      openedDate: DateTime.parse(map['openedDate'] as String),
      shelfLifeDays: map['shelfLifeDays'] as int,
      notified: (map['notified'] as int) == 1,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  ShelfItem copyWith({
    int? id,
    String? name,
    String? category,
    DateTime? openedDate,
    int? shelfLifeDays,
    bool? notified,
    String? status,
    DateTime? createdAt,
  }) {
    return ShelfItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      openedDate: openedDate ?? this.openedDate,
      shelfLifeDays: shelfLifeDays ?? this.shelfLifeDays,
      notified: notified ?? this.notified,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
