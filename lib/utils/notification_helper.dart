import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Asigură-te că folosești același obiect global ca în main.dart
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> scheduleAlarmNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
}) async {
  // Inițializează timezone doar o dată!

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    tz.TZDateTime.from(scheduledDate, tz.local),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'alarms_channel',
        'Alarme Medicamente',
        channelDescription: 'Notificări pentru alarmele de medicamente',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    ),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
    UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.dateAndTime,
  );
}
