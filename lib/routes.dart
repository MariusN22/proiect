import 'package:flutter/material.dart'; // Pentru GlobalKey<NavigatorState>
import 'package:go_router/go_router.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/login/login_screen.dart' as login;
import 'screens/login/register_screen.dart' as register;
import 'screens/patient/patient_home_screen.dart';
import 'screens/medic/medic_home_screen.dart';
import 'screens/select_medic/select_medic_screen.dart';
import 'screens/chat/patient_chat_page.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/help_screen.dart';
import 'screens/patient/pacient_alarm_screen.dart';
import 'screens/test_notification_screen.dart';
import 'appointment_screens/appointment_booking_screen.dart'; // <-- IMPORT NOU
import 'package:healthband_app/screens/settings/pacient_help_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/testNotificare',
      builder: (context, state) => const TestNotificationScreen(),
    ),
    GoRoute(
      path: '/pacientHelp',
      builder: (context, state) => const PacientHelpScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const login.LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const register.RegisterScreen(),
    ),
    GoRoute(
      path: '/homeUser',
      builder: (context, state) => const PatientHomeScreen(userRole: 'user'),
    ),
    GoRoute(
      path: '/patient/alarms',
      builder: (context, state) => const PacientAlarmScreen(),
    ),
    GoRoute(
      path: '/medicHome',
      builder: (context, state) => const MedicHomeScreen(),
    ),
    GoRoute(
      path: '/selectMedic',
      builder: (context, state) => const SelectMedicScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) {
        String role = 'user';
        if (state.extra != null &&
            state.extra is Map &&
            (state.extra as Map).containsKey('userRole')) {
          role = (state.extra as Map)['userRole'] as String;
        }
        return SettingsScreen(userRole: role);
      },
    ),
    GoRoute(
      path: '/ajutor',
      builder: (context, state) => const HelpScreen(),
    ),
    GoRoute(
      path: '/chat/:userId/:medicId',
      builder: (context, state) {
        final userId = state.params['userId']!;
        final medicId = state.params['medicId']!;
        return PatientChatPage();
      },
    ),
    GoRoute(
      path: '/appointments', // <-- NOUA RUTĂ pentru programări
      builder: (context, state) => AppointmentBookingScreen(),
    ),
  ],
);
