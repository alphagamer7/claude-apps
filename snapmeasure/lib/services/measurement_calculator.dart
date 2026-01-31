import 'dart:math' as math;

class MeasurementCalculator {
  // Known reference object sizes in millimeters
  static const Map<String, double> referenceSizes = {
    'creditCard': 85.6, // width of ISO/IEC 7810 ID-1 card
    'coin': 24.26, // US quarter diameter
    'a4paper': 297.0, // A4 long edge
  };

  // Secondary dimensions for display info
  static const Map<String, String> referenceDescriptions = {
    'creditCard': 'Credit Card width (85.6 mm)',
    'coin': 'US Quarter diameter (24.26 mm)',
    'a4paper': 'A4 Paper long edge (297 mm)',
  };

  /// Calculate the pixel-to-mm ratio from a reference calibration line.
  /// [referencePixelLength] is the pixel distance of the drawn reference line.
  /// [referenceType] is one of: creditCard, coin, a4paper.
  static double pixelToMmRatio(
      double referencePixelLength, String referenceType) {
    final knownSizeMm = referenceSizes[referenceType];
    if (knownSizeMm == null || referencePixelLength == 0) return 0;
    return knownSizeMm / referencePixelLength;
  }

  /// Calculate real distance in mm from pixel distance and ratio.
  static double realDistanceMm(double pixelLength, double ratio) {
    return pixelLength * ratio;
  }

  /// Convert mm to cm.
  static double mmToCm(double mm) => mm / 10.0;

  /// Convert mm to inches.
  static double mmToInches(double mm) => mm / 25.4;

  /// Format a dimension value with unit.
  static String formatDimension(double mm, String unit) {
    if (unit == 'inches') {
      return '${mmToInches(mm).toStringAsFixed(2)} in';
    }
    return '${mmToCm(mm).toStringAsFixed(2)} cm';
  }

  /// Calculate pixel distance between two points.
  static double pixelDistance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return math.sqrt(dx * dx + dy * dy);
  }
}
