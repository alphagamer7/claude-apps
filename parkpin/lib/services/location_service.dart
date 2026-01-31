import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  /// Request location permissions and return true if granted.
  Future<bool> requestPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  /// Check whether location services are enabled and permission is granted.
  Future<bool> isLocationAvailable() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  /// Get the current device position.
  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    );
  }

  /// Calculate distance in metres between two GPS coordinates.
  double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Calculate the bearing (in degrees, 0-360) from the current position
  /// to the target position.
  double bearingTo(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final startLatRad = _toRadians(startLat);
    final startLngRad = _toRadians(startLng);
    final endLatRad = _toRadians(endLat);
    final endLngRad = _toRadians(endLng);

    final dLng = endLngRad - startLngRad;

    final y = sin(dLng) * cos(endLatRad);
    final x = cos(startLatRad) * sin(endLatRad) -
        sin(startLatRad) * cos(endLatRad) * cos(dLng);

    final bearing = atan2(y, x);
    return (_toDegrees(bearing) + 360) % 360;
  }

  double _toRadians(double degrees) => degrees * pi / 180;
  double _toDegrees(double radians) => radians * 180 / pi;

  /// Format a distance value into a human-readable string.
  String formatDistance(double metres) {
    if (metres < 1000) {
      return '${metres.round()} m';
    }
    return '${(metres / 1000).toStringAsFixed(1)} km';
  }
}
