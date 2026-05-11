import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart'; // Новый импорт
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    if (Platform.isAndroid) {
      // Инициализация для Android (оставляем твой код)
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
      await _notifications.initialize(initSettings);

      await _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    } 
    else if (Platform.isWindows) {
      // Инициализация для Windows
      await localNotifier.setup(
        appName: 'NovaStep',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
    }
  }

  // Универсальный метод для немедленного уведомления
  static Future<void> showNotification({required String title, required String body}) async {
    if (Platform.isAndroid) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'instant_notifications', 'Instant',
        importance: Importance.max, priority: Priority.high,
      );
      await _notifications.show(0, title, body, const NotificationDetails(android: androidDetails));
    } 
    else if (Platform.isWindows) {
      LocalNotification notification = LocalNotification(
        title: title,
        body: body,
      );
      notification.show();
    }
  }

  static Future<void> scheduleDailyReminder() async {
    if (Platform.isAndroid) {
      // Твой текущий метод планирования (работает через AlarmManager в фоне)
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'daily_reminders', 'Daily Reminders',
        importance: Importance.max, priority: Priority.high,
      );
      await _notifications.zonedSchedule(
        100, 'NovaStep 📝', 'Как прошел твой день? Пора отметить настроение!',
        _nextInstanceOfNinePM(), const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
    // На Windows планирование в фоне работает иначе (через планировщик задач ОС), 
    // поэтому для начала можно просто сделать мгновенный пуш при запуске или через таймер.
  }

  static tz.TZDateTime _nextInstanceOfNinePM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 21, 0);
    if (scheduledDate.isBefore(now)) scheduledDate = scheduledDate.add(const Duration(days: 1));
    return scheduledDate;
  }

  static Future<void> cancelAll() async {
    if (Platform.isAndroid) await _notifications.cancelAll();
  }
}