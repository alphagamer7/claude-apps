class GearRatio {
  final int chainring;
  final int cog;
  final double ratio;
  final double gearInches;
  final double developmentMeters;
  final bool isOverlap;

  const GearRatio({
    required this.chainring,
    required this.cog,
    required this.ratio,
    required this.gearInches,
    required this.developmentMeters,
    this.isOverlap = false,
  });

  double speedAtCadence(double rpm, {bool imperial = false}) {
    // Speed in km/h = cadence * development(m) * 60 / 1000
    final kmh = rpm * developmentMeters * 60.0 / 1000.0;
    if (imperial) {
      return kmh * 0.621371; // Convert to mph
    }
    return kmh;
  }

  String get label => '$chainring/$cog';

  GearRatio copyWith({bool? isOverlap}) => GearRatio(
        chainring: chainring,
        cog: cog,
        ratio: ratio,
        gearInches: gearInches,
        developmentMeters: developmentMeters,
        isOverlap: isOverlap ?? this.isOverlap,
      );
}
