class CounterHistory {
  final int? id;
  final int counterId;
  final String date; // yyyy-MM-dd format
  final int value;

  CounterHistory({
    this.id,
    required this.counterId,
    required this.date,
    required this.value,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'counterId': counterId,
      'date': date,
      'value': value,
    };
  }

  factory CounterHistory.fromMap(Map<String, dynamic> map) {
    return CounterHistory(
      id: map['id'] as int?,
      counterId: map['counterId'] as int,
      date: map['date'] as String,
      value: map['value'] as int,
    );
  }
}
