import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initializeFCM(BuildContext context) async {
    // Ascultă mesajele când aplicația e în foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        // Poți face aici orice vrei, inclusiv showDialog/snackbar/local_notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.notification!.title ?? 'Notificare'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    // Poți asculta și onMessageOpenedApp pentru când userul dă tap pe notificare
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Poți naviga către anumite ecrane în funcție de payload-ul notificării
      print('Notificare deschisă din background: ${message.data}');
    });
  }
}
