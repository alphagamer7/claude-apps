import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    // Request iOS permissions
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Request Android permissions
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showQuietModeStarted(String profileName) async {
    const androidDetails = AndroidNotificationDetails(
      'quiet_hour_channel',
      'Quiet Hour',
      channelDescription: 'Notifications for QuietHour scheduling',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      0,
      'QuietHour Active',
      '$profileName - Quiet mode is now active. Enable Do Not Disturb in your device settings for full effect.',
      details,
    );
  }

  Future<void> showQuietModeEnded(String profileName) async {
    const androidDetails = AndroidNotificationDetails(
      'quiet_hour_channel',
      'Quiet Hour',
      channelDescription: 'Notifications for QuietHour scheduling',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Cancel the ongoing notification first
    await _plugin.cancel(0);

    await _plugin.show(
      1,
      'QuietHour Ended',
      '$profileName - Quiet mode has ended. You can disable Do Not Disturb now.',
      details,
    );
  }

  Future<void> showQuickActivateStarted(int durationMinutes) async {
    const androidDetails = AndroidNotificationDetails(
      'quiet_hour_channel',
      'Quiet Hour',
      channelDescription: 'Notifications for QuietHour scheduling',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      2,
      'Quick Quiet Mode Active',
      'Quiet mode for $durationMinutes minutes. Enable DND in device settings for full effect.',
      details,
    );
  }

  Future<void> showQuickActivateEnded() async {
    await _plugin.cancel(2);

    const androidDetails = AndroidNotificationDetails(
      'quiet_hour_channel',
      'Quiet Hour',
      channelDescription: 'Notifications for QuietHour scheduling',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      3,
      'Quick Quiet Mode Ended',
      'Your quick quiet session has ended. You can disable DND now.',
      details,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // Track quick-activate state via shared preferences
  Future<void> setQuickActivateEnd(DateTime endTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'quick_activate_end', endTime.toIso8601String());
  }

  Future<DateTime?> getQuickActivateEnd() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('quick_activate_end');
    if (str == null) return null;
    final dt = DateTime.parse(str);
    if (dt.isBefore(DateTime.now())) {
      await prefs.remove('quick_activate_end');
      return null;
    }
    return dt;
  }

  Future<void> clearQuickActivate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('quick_activate_end');
  }
}
