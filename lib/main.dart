import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'core/theme_notifier.dart';
import 'routes.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await EasyLocalization.ensureInitialized();

  // Notificări locale: inițializare timezone (O SINGURĂ DATĂ la pornire!)
  tz.initializeTimeZones();

  // Inițializare notificări locale
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    // Poți adăuga și pentru iOS dacă vrei
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Permisiuni FCM (pentru push)
  await FirebaseMessaging.instance.requestPermission();

  // Printează tokenul FCM (îl vei folosi la login)
  final fcmToken = await FirebaseMessaging.instance.getToken();
  print('FCM Token: $fcmToken'); // <-- Vezi tokenul în terminal

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ro'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ro'),
      child: ChangeNotifierProvider(
        create: (_) => ThemeNotifier(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, _) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'HealthBand App',
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF217A6B),
            scaffoldBackgroundColor: const Color(0xFFF6FAF9),
            drawerTheme: const DrawerThemeData(
              backgroundColor: Color(0xFF217A6B),
            ),
            cardColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF217A6B),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Color(0xFF217A6B),
              unselectedItemColor: Colors.grey,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF217A6B),
            scaffoldBackgroundColor: const Color(0xFF181A20),
            drawerTheme: const DrawerThemeData(
              backgroundColor: Color(0xFF232323),
            ),
            cardColor: const Color(0xFF232323),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF232323),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF232323),
              selectedItemColor: Color(0xFF6DD5ED),
              unselectedItemColor: Colors.white70,
            ),
          ),
          themeMode: themeNotifier.themeMode,
          routerConfig: router,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
        );
      },
    );
  }
}
