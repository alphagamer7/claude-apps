import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';
import 'database_service.dart';

const String taskCheckSchedules = 'com.quiethour.checkSchedules';
const String taskQuickActivateEnd = 'com.quiethour.quickActivateEnd';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final notificationService = NotificationService();
    await notificationService.initialize();

    switch (task) {
      case taskCheckSchedules:
        await _checkActiveSchedules(notificationService);
        break;
      case taskQuickActivateEnd:
        await notificationService.showQuickActivateEnded();
        await notificationService.clearQuickActivate();
        break;
    }
    return true;
  });
}

Future<void> _checkActiveSchedules(NotificationService notifService) async {
  final dbService = DatabaseService();
  final profiles = await dbService.getAllProfiles();
  final now = DateTime.now();
  final dayIndex = now.weekday - 1; // 0=Mon ... 6=Sun

  for (final profile in profiles) {
    if (!profile.isEnabled) continue;
    if (!profile.activeDays[dayIndex]) continue;

    final startMinutes = profile.startTime.hour * 60 + profile.startTime.minute;
    final endMinutes = profile.endTime.hour * 60 + profile.endTime.minute;
    final nowMinutes = now.hour * 60 + now.minute;

    bool isActive;
    if (endMinutes > startMinutes) {
      isActive = nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      // Crosses midnight
      isActive = nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }

    if (isActive) {
      await notifService.showQuietModeStarted(profile.name);
      return;
    }
  }
}

class SchedulerService {
  static final SchedulerService _instance = SchedulerService._internal();
  factory SchedulerService() => _instance;
  SchedulerService._internal();

  Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  Future<void> schedulePeriodicCheck() async {
    await Workmanager().registerPeriodicTask(
      'quiethour_periodic_check',
      taskCheckSchedules,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  Future<void> scheduleQuickActivateEnd(Duration duration) async {
    await Workmanager().registerOneOffTask(
      'quiethour_quick_end',
      taskQuickActivateEnd,
      initialDelay: duration,
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  Future<void> cancelQuickActivateEnd() async {
    await Workmanager().cancelByUniqueName('quiethour_quick_end');
  }

  Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }
}
