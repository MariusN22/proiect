import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../call/call_listener_widget.dart';
import 'pacient_alarm_screen.dart';
import '../pulse/vitals_chart.dart'; // ecranul de funcții vitale
import '../profile/medic_profile_screen.dart';
import '../chat/patient_chat_page.dart';
import '../profile/patient_profile_screen.dart';
import 'lista_apeluri_medici_screen.dart';
import '../../appointment_screens/appointment_booking_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  final String userRole;
  const PatientHomeScreen({super.key, required this.userRole});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _currentIndex = 0;
  String userName = "loading".tr();

  final Color themeGreen = const Color(0xFF217A6B);

  @override
  void initState() {
    super.initState();
    _getUserName();
    _saveFCMTokenToFirestore();
    _initFCMForegroundHandler();
  }

  Future<void> _getUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      setState(() {
        userName = ((data?['nume'] ?? '') + " " + (data?['prenume'] ?? '')).trim();
        if (userName.isEmpty) userName = "user".tr();
      });
    }
  }

  Future<void> _saveFCMTokenToFirestore() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
        'fcmToken': fcmToken,
      });
    }
  }

  void _initFCMForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final notif = message.notification!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${notif.title ?? "Notificare"}\n${notif.body ?? ""}',
              style: const TextStyle(fontSize: 16),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  void _onNavTapped(int idx) {
    setState(() => _currentIndex = idx);
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  List<Widget> get _pages => [
    _HomeDashboard(cards: _mainCards),       // Home tab
    const PatientChatPage(),                 // Mesaje
    AppointmentBookingScreen(),              // Programări
    const PatientProfileScreen(),            // Profil
  ];

  List<Widget> get _mainCards {
    return [
      _HomeCard(
        title: "functii_vitale".tr(),
        icon: Icons.monitor_heart,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => VitalsChartScreen()));
        },
      ),
      _HomeCard(
        title: "medicine_alarms".tr(),
        icon: Icons.alarm,
        onTap: () {
          context.push('/patient/alarms');
        },
      ),
      _HomeCard(
        title: "calls".tr(),
        icon: Icons.call,
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ListaApeluriMediciScreen()));
        },
      ),
      if (widget.userRole == "user")
        _HomeCard(
          title: "select_doctor".tr(),
          icon: Icons.medical_services,
          onTap: () {
            context.push('/selectMedic');
          },
        ),
    ];
  }

  // ====== MODIFICARE logout confirmare ======
  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('logout_confirm'.tr()), // pune cheia în json, vezi mai jos
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('no'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('yes'.tr()),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _logout();
    }
  }
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF232323) : themeGreen,
        child: ListView(
          children: [
            DrawerHeader(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 48, color: Color(0xFF217A6B)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.userRole == "medic")
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: Text("profile".tr(), style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MedicProfileScreen()),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: Text("settings".tr(), style: const TextStyle(color: Colors.white)),
              onTap: () {
                context.push('/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: Text("about".tr(), style: const TextStyle(color: Colors.white)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    title: Text("about".tr()),
                    content: Text("about_text".tr()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text("inchide".tr()),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.white),
              title: Text("ajutor".tr(), style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/pacientHelp');
              },
            ),
            // ======= LOGOUT CU CONFIRMARE =======
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: Text("logout".tr(), style: const TextStyle(color: Colors.white)),
              onTap: _confirmLogout,
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const SizedBox.shrink(),
        backgroundColor: isDark ? const Color(0xFF232323) : themeGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Stack(
        children: [
          _pages[_currentIndex],
          const CallListenerWidget(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF232323) : Colors.white,
        selectedItemColor: themeGreen,
        unselectedItemColor: Colors.grey[500],
        selectedLabelStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 18),
        iconSize: 45,
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home, size: 45), label: "home".tr()),
          BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline, size: 45), label: "messages".tr()),
          BottomNavigationBarItem(
            icon: const Icon(Icons.event_available, size: 45),
            label: "appointments".tr(),
          ),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person, size: 45), label: "profile".tr()),
        ],
      ),
    );
  }
}

// ---- Widget pentru dashboard ----
class _HomeDashboard extends StatelessWidget {
  final List<Widget> cards;
  const _HomeDashboard({required this.cards});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF18191B) : const Color(0xFFEFF6F4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(height: 18),
        itemBuilder: (ctx, i) => cards[i],
      ),
    );
  }
}

// ---- Card personalizat pentru funcțiile principale ----
class _HomeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _HomeCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(18),
      color: isDark ? const Color(0xFF232323) : const Color(0xFF217A6B),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 22),
          child: Row(
            children: [
              Icon(icon, size: 38, color: Colors.white),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
