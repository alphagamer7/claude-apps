import 'dart:convert';
import 'split_item.dart';

class SplitSession {
  int? id;
  List<SplitItem> items;
  List<String> people;
  double taxAmount;
  double tipAmount;
  DateTime date;

  SplitSession({
    this.id,
    required this.items,
    required this.people,
    this.taxAmount = 0.0,
    this.tipAmount = 0.0,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.price);

  double get total => subtotal + taxAmount + tipAmount;

  /// Calculate each person's share with proportional tax/tip.
  Map<String, double> getPerPersonTotals() {
    final totals = <String, double>{};
    for (final person in people) {
      totals[person] = 0.0;
    }

    // Add up item prices per person
    for (final item in items) {
      if (item.assignedPerson != null && totals.containsKey(item.assignedPerson)) {
        totals[item.assignedPerson!] = totals[item.assignedPerson!]! + item.price;
      }
    }

    // Proportionally split tax and tip based on each person's subtotal
    final sub = subtotal;
    if (sub > 0) {
      for (final person in people) {
        final personSubtotal = totals[person]!;
        final proportion = personSubtotal / sub;
        totals[person] = personSubtotal +
            (taxAmount * proportion) +
            (tipAmount * proportion);
      }
    }

    return totals;
  }

  /// Get items assigned to a specific person.
  List<SplitItem> getItemsForPerson(String person) {
    return items.where((item) => item.assignedPerson == person).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': jsonEncode(items.map((i) => i.toMap()).toList()),
      'people': jsonEncode(people),
      'taxAmount': taxAmount,
      'tipAmount': tipAmount,
      'date': date.toIso8601String(),
    };
  }

  factory SplitSession.fromMap(Map<String, dynamic> map) {
    final itemsList = (jsonDecode(map['items'] as String) as List)
        .map((i) => SplitItem.fromMap(i as Map<String, dynamic>))
        .toList();
    final peopleList = (jsonDecode(map['people'] as String) as List)
        .map((p) => p as String)
        .toList();

    return SplitSession(
      id: map['id'] as int?,
      items: itemsList,
      people: peopleList,
      taxAmount: (map['taxAmount'] as num).toDouble(),
      tipAmount: (map['tipAmount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
    );
  }
}
