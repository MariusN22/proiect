import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../../../main.dart'; // adaptează calea dacă e nevoie

class TestNotificationScreen extends StatelessWidget {
  const TestNotificationScreen({super.key});

  Future<void> scheduleTestNotification() async {
    print("PAS 1: Încerc să cer permisiunea de alarmă exactă...");
    final status = await Permission.scheduleExactAlarm.status;
    if (!status.isGranted) {
      final result = await Permission.scheduleExactAlarm.request();
      print("PAS 1.1: Permisiune acordată? ${result.isGranted}");
      if (!result.isGranted) {
        print("Permisiunea pentru alarme exacte NU a fost acordată!");
        return;
      }
    }
    print("PAS 2: Programare notificare pentru 30 secunde de acum...");
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = now.add(const Duration(seconds: 30));
    print("PAS 3: Timp programare: $scheduled");

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        9999,
        'Test Alarmă',
        'Aceasta este o alarmă programată!',
        scheduled,
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
      print("PAS 4: Notificarea a fost programată cu succes!");
    } catch (e) {
      print("EROARE la programarea notificării: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Notificare')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                // Notificare instant
                print("=== NOTIFICARE INSTANT ===");
                await flutterLocalNotificationsPlugin.show(
                  9999,
                  'Test instant',
                  'Aceasta e o notificare INSTANT. Dacă o vezi, notificările funcționează!',
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
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notificare instant trimisă!')),
                );
              },
              child: const Text('Trimite notificare instant'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                // Notificare programată la 30 secunde
                await scheduleTestNotification();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notificarea a fost programată (30 secunde)! Verifică log-ul!')),
                );
              },
              child: const Text('Trimite notificare de test în 30 secunde'),
            ),
          ],
        ),
      ),
    );
  }
}
