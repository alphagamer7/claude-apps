import 'dart:convert';

enum RandomizerType { coinFlip, diceRoll, spinner, drawStraws }

class RandomizerResult {
  final int? id;
  final RandomizerType type;
  final String outcome;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  RandomizerResult({
    this.id,
    required this.type,
    required this.outcome,
    this.details,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'outcome': outcome,
        'details': details != null ? jsonEncode(details) : null,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RandomizerResult.fromMap(Map<String, dynamic> map) {
    return RandomizerResult(
      id: map['id'] as int?,
      type: RandomizerType.values.firstWhere((e) => e.name == map['type']),
      outcome: map['outcome'] as String,
      details: map['details'] != null
          ? jsonDecode(map['details'] as String) as Map<String, dynamic>
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  RandomizerResult copyWith({int? id}) => RandomizerResult(
        id: id ?? this.id,
        type: type,
        outcome: outcome,
        details: details,
        createdAt: createdAt,
      );
}
