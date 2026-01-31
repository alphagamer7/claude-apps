import '../models/drivetrain.dart';
import '../models/gear_ratio.dart';

class GearCalculator {
  /// Calculate all gear ratios for a drivetrain
  static List<GearRatio> calculateAll(Drivetrain drivetrain) {
    final ratios = <GearRatio>[];

    for (final chainring in drivetrain.chainrings) {
      for (final cog in drivetrain.cassette) {
        final ratio = chainring / cog.toDouble();
        final gearInches = ratio * drivetrain.wheelDiameterInches;
        final developmentMeters =
            ratio * drivetrain.wheelCircumferenceMeters;

        ratios.add(GearRatio(
          chainring: chainring,
          cog: cog,
          ratio: ratio,
          gearInches: gearInches,
          developmentMeters: developmentMeters,
        ));
      }
    }

    return _markOverlaps(ratios, drivetrain.chainrings);
  }

  /// Find gears within 5% ratio of each other from different chainrings
  static List<GearRatio> _markOverlaps(
      List<GearRatio> ratios, List<int> chainrings) {
    if (chainrings.length < 2) return ratios;

    final result = <GearRatio>[];

    for (final gear in ratios) {
      bool overlap = false;
      for (final other in ratios) {
        if (gear.chainring != other.chainring) {
          final diff = (gear.ratio - other.ratio).abs() / gear.ratio;
          if (diff < 0.05) {
            overlap = true;
            break;
          }
        }
      }
      result.add(gear.copyWith(isOverlap: overlap));
    }

    return result;
  }

  /// Get ratios grouped by chainring
  static Map<int, List<GearRatio>> groupByChainring(List<GearRatio> ratios) {
    final grouped = <int, List<GearRatio>>{};
    for (final ratio in ratios) {
      grouped.putIfAbsent(ratio.chainring, () => []).add(ratio);
    }
    return grouped;
  }

  /// Get all ratios sorted by ratio value
  static List<GearRatio> sortedByRatio(List<GearRatio> ratios,
      {bool ascending = true}) {
    final sorted = List<GearRatio>.from(ratios);
    sorted.sort((a, b) =>
        ascending ? a.ratio.compareTo(b.ratio) : b.ratio.compareTo(a.ratio));
    return sorted;
  }

  /// Calculate the percentage gap between consecutive gears for a chainring
  static List<double> gearGaps(List<GearRatio> ratiosForChainring) {
    final sorted = List<GearRatio>.from(ratiosForChainring);
    sorted.sort((a, b) => a.ratio.compareTo(b.ratio));

    final gaps = <double>[];
    for (int i = 1; i < sorted.length; i++) {
      final gap =
          ((sorted[i].ratio - sorted[i - 1].ratio) / sorted[i - 1].ratio) *
              100;
      gaps.add(gap);
    }
    return gaps;
  }

  /// Find the overlap pairs between different chainrings
  static List<({GearRatio a, GearRatio b, double percentDiff})>
      findOverlapPairs(List<GearRatio> ratios) {
    final pairs =
        <({GearRatio a, GearRatio b, double percentDiff})>[];

    for (int i = 0; i < ratios.length; i++) {
      for (int j = i + 1; j < ratios.length; j++) {
        if (ratios[i].chainring != ratios[j].chainring) {
          final diff =
              (ratios[i].ratio - ratios[j].ratio).abs() / ratios[i].ratio;
          if (diff < 0.05) {
            pairs.add((
              a: ratios[i],
              b: ratios[j],
              percentDiff: diff * 100,
            ));
          }
        }
      }
    }

    pairs.sort((a, b) => a.percentDiff.compareTo(b.percentDiff));
    return pairs;
  }
}
