import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/shelf_item.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

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

    await _notifications.initialize(settings);
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> scheduleExpiryNotifications(ShelfItem item) async {
    if (item.id == null) return;

    final now = DateTime.now();
    final expiryDate = item.expiryDate;
    final dayBeforeExpiry = expiryDate.subtract(const Duration(days: 1));

    // Notification 1 day before expiry
    if (dayBeforeExpiry.isAfter(now)) {
      final scheduledDate = DateTime(
        dayBeforeExpiry.year,
        dayBeforeExpiry.month,
        dayBeforeExpiry.day,
        9,
        0,
      );

      if (scheduledDate.isAfter(now)) {
        await _notifications.zonedSchedule(
          item.id! * 2,
          'ShelfLife Reminder',
          '${item.name} expires tomorrow, use it up!',
          tz.TZDateTime.from(scheduledDate, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'shelflife_expiry',
              'Expiry Reminders',
              channelDescription: 'Notifications for items about to expire',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }

    // Notification on expiry day
    final expiryNotifDate = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
      9,
      0,
    );

    if (expiryNotifDate.isAfter(now)) {
      await _notifications.zonedSchedule(
        item.id! * 2 + 1,
        'ShelfLife Alert',
        '${item.name} has expired',
        tz.TZDateTime.from(expiryNotifDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'shelflife_expiry',
            'Expiry Reminders',
            channelDescription: 'Notifications for items about to expire',
            importance: Importance.max,
            priority: Priority.max,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelNotifications(int itemId) async {
    await _notifications.cancel(itemId * 2);
    await _notifications.cancel(itemId * 2 + 1);
  }
}
