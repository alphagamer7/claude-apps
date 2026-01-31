class SplitItem {
  String name;
  double price;
  String? assignedPerson;

  SplitItem({
    required this.name,
    required this.price,
    this.assignedPerson,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'assignedPerson': assignedPerson,
    };
  }

  factory SplitItem.fromMap(Map<String, dynamic> map) {
    return SplitItem(
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      assignedPerson: map['assignedPerson'] as String?,
    );
  }

  SplitItem copyWith({
    String? name,
    double? price,
    String? assignedPerson,
    bool clearPerson = false,
  }) {
    return SplitItem(
      name: name ?? this.name,
      price: price ?? this.price,
      assignedPerson: clearPerson ? null : (assignedPerson ?? this.assignedPerson),
    );
  }
}
