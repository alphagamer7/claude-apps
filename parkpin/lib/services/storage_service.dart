import 'package:shared_preferences/shared_preferences.dart';
import '../models/parking_pin.dart';
import '../models/timer_state.dart';

export '../models/parking_pin.dart';
export '../models/timer_state.dart';

class StorageService {
  static const _keyLat = 'pin_latitude';
  static const _keyLng = 'pin_longitude';
  static const _keyPhoto = 'pin_photo';
  static const _keyTimestamp = 'pin_timestamp';
  static const _keyTimerEnd = 'timer_end';

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save a parking pin.
  Future<void> savePin(double lat, double lng) async {
    await _prefs.setDouble(_keyLat, lat);
    await _prefs.setDouble(_keyLng, lng);
    await _prefs.setString(
      _keyTimestamp,
      DateTime.now().toIso8601String(),
    );
  }

  /// Save the photo path associated with the pin.
  Future<void> savePhoto(String path) async {
    await _prefs.setString(_keyPhoto, path);
  }

  /// Load the saved parking pin, or null if none exists.
  ParkingPin? loadPin() {
    final lat = _prefs.getDouble(_keyLat);
    final lng = _prefs.getDouble(_keyLng);
    final tsStr = _prefs.getString(_keyTimestamp);
    if (lat == null || lng == null || tsStr == null) return null;

    return ParkingPin(
      latitude: lat,
      longitude: lng,
      photoPath: _prefs.getString(_keyPhoto),
      timestamp: DateTime.parse(tsStr),
    );
  }

  /// Clear the saved pin.
  Future<void> clearPin() async {
    await _prefs.remove(_keyLat);
    await _prefs.remove(_keyLng);
    await _prefs.remove(_keyPhoto);
    await _prefs.remove(_keyTimestamp);
    await _prefs.remove(_keyTimerEnd);
  }

  /// Save a parking timer end time.
  Future<void> saveTimer(DateTime endTime) async {
    await _prefs.setString(_keyTimerEnd, endTime.toIso8601String());
  }

  /// Load the parking timer state, or null if none is set.
  TimerState? loadTimer() {
    final endStr = _prefs.getString(_keyTimerEnd);
    if (endStr == null) return null;
    return TimerState(endTime: DateTime.parse(endStr));
  }

  /// Clear the parking timer.
  Future<void> clearTimer() async {
    await _prefs.remove(_keyTimerEnd);
  }
}
