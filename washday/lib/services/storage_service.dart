import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _washDurationKey = 'wash_duration_minutes';
  static const String _dryDurationKey = 'dry_duration_minutes';
  static const String _notificationSoundKey = 'notification_sound';

  static const String _washStartTimeKey = 'wash_start_time';
  static const String _washDurationMsKey = 'wash_duration_ms';
  static const String _washRunningKey = 'wash_running';

  static const String _dryStartTimeKey = 'dry_start_time';
  static const String _dryDurationMsKey = 'dry_duration_ms';
  static const String _dryRunningKey = 'dry_running';

  static const String _weeklyCountKey = 'weekly_count';
  static const String _weekStartDateKey = 'week_start_date';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Durations (in minutes)
  int getWashDuration() => _prefs.getInt(_washDurationKey) ?? 45;
  Future<void> setWashDuration(int minutes) =>
      _prefs.setInt(_washDurationKey, minutes);

  int getDryDuration() => _prefs.getInt(_dryDurationKey) ?? 60;
  Future<void> setDryDuration(int minutes) =>
      _prefs.setInt(_dryDurationKey, minutes);

  // Notification sound
  bool getNotificationSound() => _prefs.getBool(_notificationSoundKey) ?? true;
  Future<void> setNotificationSound(bool enabled) =>
      _prefs.setBool(_notificationSoundKey, enabled);

  // Timer state - Wash
  bool getWashRunning() => _prefs.getBool(_washRunningKey) ?? false;
  int? getWashStartTime() {
    final val = _prefs.getInt(_washStartTimeKey);
    return val;
  }

  int? getWashDurationMs() {
    final val = _prefs.getInt(_washDurationMsKey);
    return val;
  }

  Future<void> saveWashTimerState({
    required int startTimeMs,
    required int durationMs,
    required bool isRunning,
  }) async {
    await _prefs.setInt(_washStartTimeKey, startTimeMs);
    await _prefs.setInt(_washDurationMsKey, durationMs);
    await _prefs.setBool(_washRunningKey, isRunning);
  }

  Future<void> clearWashTimerState() async {
    await _prefs.remove(_washStartTimeKey);
    await _prefs.remove(_washDurationMsKey);
    await _prefs.setBool(_washRunningKey, false);
  }

  // Timer state - Dry
  bool getDryRunning() => _prefs.getBool(_dryRunningKey) ?? false;
  int? getDryStartTime() {
    final val = _prefs.getInt(_dryStartTimeKey);
    return val;
  }

  int? getDryDurationMs() {
    final val = _prefs.getInt(_dryDurationMsKey);
    return val;
  }

  Future<void> saveDryTimerState({
    required int startTimeMs,
    required int durationMs,
    required bool isRunning,
  }) async {
    await _prefs.setInt(_dryStartTimeKey, startTimeMs);
    await _prefs.setInt(_dryDurationMsKey, durationMs);
    await _prefs.setBool(_dryRunningKey, isRunning);
  }

  Future<void> clearDryTimerState() async {
    await _prefs.remove(_dryStartTimeKey);
    await _prefs.remove(_dryDurationMsKey);
    await _prefs.setBool(_dryRunningKey, false);
  }

  // Weekly counter
  int getWeeklyCount() {
    _checkWeekReset();
    return _prefs.getInt(_weeklyCountKey) ?? 0;
  }

  Future<void> incrementWeeklyCount() async {
    _checkWeekReset();
    final current = _prefs.getInt(_weeklyCountKey) ?? 0;
    await _prefs.setInt(_weeklyCountKey, current + 1);
  }

  Future<void> resetWeeklyCount() async {
    await _prefs.setInt(_weeklyCountKey, 0);
    await _prefs.setString(
      _weekStartDateKey,
      _getMonday(DateTime.now()).toIso8601String(),
    );
  }

  void _checkWeekReset() {
    final storedDateStr = _prefs.getString(_weekStartDateKey);
    final currentMonday = _getMonday(DateTime.now());

    if (storedDateStr == null) {
      _prefs.setString(_weekStartDateKey, currentMonday.toIso8601String());
      return;
    }

    final storedMonday = DateTime.parse(storedDateStr);
    if (currentMonday.isAfter(storedMonday)) {
      _prefs.setInt(_weeklyCountKey, 0);
      _prefs.setString(_weekStartDateKey, currentMonday.toIso8601String());
    }
  }

  DateTime _getMonday(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }
}
