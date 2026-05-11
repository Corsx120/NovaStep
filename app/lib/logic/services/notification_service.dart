import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Инициализация часовых поясов
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);

    // ЗАПРАШИВАЕМ РАЗРЕШЕНИЕ (Для Android 13+)
    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  // Метод для планирования ежедневного уведомления на 21:00
  static Future<void> scheduleDailyReminder() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminders', 
      'Daily Reminders',
      channelDescription: 'Daily notifications to check mood',
      importance: Importance.max, 
      priority: Priority.high,
    );
    
    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      100,
      'NovaStep 📝',
      'Как прошел твой день? Пора отметить настроение!',
      _nextInstanceOfNinePM(),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Это заставляет его повторяться каждый день в это время
    );
  }

  // Вспомогательный метод для расчета времени (21:00)
  static tz.TZDateTime _nextInstanceOfNinePM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 21, 0);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // Метод для отмены уведомлений (если пользователь выключил их в настройках)
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}