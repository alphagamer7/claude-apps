import '../models/focus_session.dart';
import 'database_service.dart';

class StreakService {
  final DatabaseService _db = DatabaseService();

  Future<int> getCurrentStreak() async {
    final sessions = await _db.getCompletedSessions();
    if (sessions.isEmpty) return 0;

    final daysWithSessions = _getDaysWithCompletedSessions(sessions);
    if (daysWithSessions.isEmpty) return 0;

    final today = _dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    // Streak must include today or yesterday
    if (!daysWithSessions.contains(today) &&
        !daysWithSessions.contains(yesterday)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate =
        daysWithSessions.contains(today) ? today : yesterday;

    while (daysWithSessions.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Future<int> getBestStreak() async {
    final sessions = await _db.getCompletedSessions();
    if (sessions.isEmpty) return 0;

    final daysWithSessions = _getDaysWithCompletedSessions(sessions);
    if (daysWithSessions.isEmpty) return 0;

    final sortedDays = daysWithSessions.toList()..sort();
    int bestStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < sortedDays.length; i++) {
      final diff = sortedDays[i].difference(sortedDays[i - 1]).inDays;
      if (diff == 1) {
        currentStreak++;
        if (currentStreak > bestStreak) {
          bestStreak = currentStreak;
        }
      } else {
        currentStreak = 1;
      }
    }

    return bestStreak;
  }

  Future<int> getWeeklySessionCount() async {
    final sessions = await _db.getAllSessions();
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    return sessions
        .where((s) => s.completed && s.startTime.isAfter(weekAgo))
        .length;
  }

  Future<int> getWeeklyFocusMinutes() async {
    final sessions = await _db.getAllSessions();
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    return sessions
        .where((s) => s.completed && s.startTime.isAfter(weekAgo))
        .fold<int>(0, (sum, s) => sum + s.durationMinutes);
  }

  Set<DateTime> _getDaysWithCompletedSessions(List<FocusSession> sessions) {
    return sessions
        .where((s) => s.completed)
        .map((s) => _dateOnly(s.startTime))
        .toSet();
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
