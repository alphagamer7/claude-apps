class ParkingPin {
  final double latitude;
  final double longitude;
  final String? photoPath;
  final DateTime timestamp;

  ParkingPin({
    required this.latitude,
    required this.longitude,
    this.photoPath,
    required this.timestamp,
  });
}
