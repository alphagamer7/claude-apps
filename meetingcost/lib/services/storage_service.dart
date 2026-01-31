import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _keyDefaultRate = 'default_hourly_rate';
  static const _keyDefaultAttendees = 'default_attendee_count';

  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  Future<void> saveDefaultRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyDefaultRate, rate);
  }

  Future<double> getDefaultRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyDefaultRate) ?? 75.0;
  }

  Future<void> saveDefaultAttendees(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDefaultAttendees, count);
  }

  Future<int> getDefaultAttendees() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDefaultAttendees) ?? 5;
  }
}
