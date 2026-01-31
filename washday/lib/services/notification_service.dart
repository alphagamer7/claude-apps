import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int washNotificationId = 1;
  static const int dryNotificationId = 2;

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings);
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request Android permissions
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    // Request iOS permissions
    final iosPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required Duration delay,
    bool playSound = true,
  }) async {
    // Cancel any existing notification with this ID first
    await _plugin.cancel(id);

    final androidDetails = AndroidNotificationDetails(
      'washday_channel',
      'WashDay Notifications',
      channelDescription: 'Laundry cycle completion alerts',
      importance: Importance.high,
      priority: Priority.high,
      playSound: playSound,
    );

    final darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: playSound,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      _scheduleDelayed(id, title, body, details, delay);
    } catch (e) {
      debugPrint('Notification scheduling error: $e');
    }
  }

  void _scheduleDelayed(
    int id,
    String title,
    String body,
    NotificationDetails details,
    Duration delay,
  ) {
    Future.delayed(delay, () async {
      try {
        await _plugin.show(id, title, body, details);
      } catch (e) {
        debugPrint('Notification show error: $e');
      }
    });
  }

  Future<void> scheduleWashDone({
    required Duration delay,
    bool playSound = true,
  }) async {
    await scheduleNotification(
      id: washNotificationId,
      title: 'Wash Complete!',
      body: 'Your wash is done! Time to switch.',
      delay: delay,
      playSound: playSound,
    );
  }

  Future<void> scheduleDryDone({
    required Duration delay,
    bool playSound = true,
  }) async {
    await scheduleNotification(
      id: dryNotificationId,
      title: 'Dryer Complete!',
      body: 'Your clothes are dry!',
      delay: delay,
      playSound: playSound,
    );
  }

  Future<void> cancelWashNotification() async {
    await _plugin.cancel(washNotificationId);
  }

  Future<void> cancelDryNotification() async {
    await _plugin.cancel(dryNotificationId);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
