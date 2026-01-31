class CostCalculator {
  final int attendeeCount;
  final double hourlyRate;

  const CostCalculator({
    required this.attendeeCount,
    required this.hourlyRate,
  });

  double get costPerSecond => (attendeeCount * hourlyRate) / 3600;
  double get costPerMinute => costPerSecond * 60;

  double totalCost(int elapsedSeconds) => costPerSecond * elapsedSeconds;

  static List<FunEquivalent> funEquivalents(double totalCost) {
    final equivalents = <FunEquivalent>[
      FunEquivalent(
        name: 'cups of coffee',
        icon: 'coffee',
        unitCost: 5.0,
        count: totalCost / 5.0,
      ),
      FunEquivalent(
        name: 'lunches',
        icon: 'lunch',
        unitCost: 15.0,
        count: totalCost / 15.0,
      ),
      FunEquivalent(
        name: 'Netflix subscriptions',
        icon: 'netflix',
        unitCost: 15.49,
        count: totalCost / 15.49,
      ),
      FunEquivalent(
        name: 'Spotify subscriptions',
        icon: 'music',
        unitCost: 11.99,
        count: totalCost / 11.99,
      ),
      FunEquivalent(
        name: 'Uber rides',
        icon: 'car',
        unitCost: 25.0,
        count: totalCost / 25.0,
      ),
      FunEquivalent(
        name: 'movie tickets',
        icon: 'movie',
        unitCost: 16.0,
        count: totalCost / 16.0,
      ),
      FunEquivalent(
        name: 'books',
        icon: 'book',
        unitCost: 20.0,
        count: totalCost / 20.0,
      ),
      FunEquivalent(
        name: 'pizzas',
        icon: 'pizza',
        unitCost: 18.0,
        count: totalCost / 18.0,
      ),
    ];
    // Return only equivalents where at least 1 unit
    return equivalents.where((e) => e.count >= 1.0).toList();
  }
}

class FunEquivalent {
  final String name;
  final String icon;
  final double unitCost;
  final double count;

  const FunEquivalent({
    required this.name,
    required this.icon,
    required this.unitCost,
    required this.count,
  });
}
