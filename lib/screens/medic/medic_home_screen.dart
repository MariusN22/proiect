import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Elimină importurile Zego pentru signaling și invitație!
/* import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart'; */

import 'medic_lista_pacienti_page.dart';
import '../chat/medic_chat_page.dart';
import 'selecteaza_pacient_screen.dart';
import 'edit_medic_profile_page.dart';
import 'alarme_medic_screen.dart';
import 'lista_apeluri_pacienti_screen.dart';

// ---- Importă widgetul pentru listener la apeluri ----
import '../call/call_listener_widget.dart'; // Modifică calea după structura proiectului tău

// --- Importă calendarul cu programări pentru medic ---
import '../../appointment_screens/medic_appointments_screen.dart'; // <-- Asta trebuie să existe!

class MedicHomeScreen extends StatefulWidget {
  const MedicHomeScreen({super.key});

  @override
  State<MedicHomeScreen> createState() => _MedicHomeScreenState();
}

class _MedicHomeScreenState extends State<MedicHomeScreen> {
  int _currentIndex = 0;
  String medicName = "loading".tr();
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    _getMedicName();
    // _initZegoCallInvitationService(); // <-- scoate Zego signaling!
    _saveFCMTokenToFirestore();
    _initFCMForegroundHandler(); // <-- handler pt notificări foreground
  }

  Future<void> _getMedicName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      setState(() {
        medicName = ((data?['nume'] ?? '') + " " + (data?['prenume'] ?? '')).trim();
        if (medicName.isEmpty) medicName = "doctor".tr();
        photoUrl = data?['photoUrl'] ?? null;
      });
    }
  }

  // ------ Inițializare Zego Call Invitation SCOASĂ! ------
  // void _initZegoCallInvitationService() async { ... }  // Eliminat complet

  // ------ SALVARE FCM TOKEN (pentru notificare push) ------
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
  // --------------------------------------------------------

  // ------ HANDLER NOTIFICARE FOREGROUND ------
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
  // -------------------------------------------

  void _onNavTapped(int idx) {
    setState(() => _currentIndex = idx);
  }

  Future<void> _logoutWithConfirm() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('logout_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('no'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('yes'.tr()),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  List<Widget> get _pages => [
    _MedicDashboard(),
    MedicChatPage(),
    MedicAppointmentsScreen(), // <-- Calendarul și programările medicului (nu _ProgramariMedicPage)
    MedicListaPacientiTab(),
    _MedicProfilePage(onLogout: _logoutWithConfirm),
  ];

  Color getIconColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF232323) : const Color(0xFF217A6B),
        child: ListView(
          children: [
            DrawerHeader(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Theme.of(context).cardColor,
                    backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                        ? NetworkImage(photoUrl!)
                        : null,
                    child: (photoUrl == null || photoUrl!.isEmpty)
                        ? Icon(Icons.person, size: 48, color: isDark ? Colors.white : const Color(0xFF217A6B))
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    medicName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: Text("settings".tr(), style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: Text("about".tr(), style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('about'.tr()),
                    content: Text('about_app'.tr()),
                    actions: [
                      TextButton(
                        child: Text('close'.tr()),
                        onPressed: () => Navigator.of(context).pop(),
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
                context.push('/ajutor');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: Text("logout".tr(), style: const TextStyle(color: Colors.white)),
              onTap: _logoutWithConfirm,
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: null,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: getIconColor(context),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: getIconColor(context)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Stack(
        children: [
          _pages[_currentIndex],
          // ---- Call Listener pentru apeluri primite ----
          const CallListenerWidget(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: isDark ? const Color(0xFF232323) : Colors.white,
      selectedItemColor: isDark ? Colors.tealAccent : const Color(0xFF217A6B),
      unselectedItemColor: Colors.grey[500],
      selectedLabelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontSize: 16),
      iconSize: 42,
      currentIndex: _currentIndex,
      onTap: _onNavTapped,
      items: [
        BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 42, color: isDark ? Colors.white : Theme.of(context).primaryColor),
            label: "home".tr()),
        BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline, size: 42, color: isDark ? Colors.white : Theme.of(context).primaryColor),
            label: "messages".tr()),
        BottomNavigationBarItem(
            icon: Icon(Icons.event_available, size: 42, color: isDark ? Colors.white : Theme.of(context).primaryColor),
            label: "appointments".tr()),
        BottomNavigationBarItem(
            icon: Icon(Icons.people, size: 42, color: isDark ? Colors.white : Theme.of(context).primaryColor),
            label: "patients".tr()),
        BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 42, color: isDark ? Colors.white : Theme.of(context).primaryColor),
            label: "profile".tr()),
      ],
    );
  }
}

// ---- Dashboard Medic ----
class _MedicDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF18191B) : const Color(0xFFEFF6F4),
      padding: const EdgeInsets.all(18),
      child: ListView(
        children: [
          _MedicHomeCard(
            title: "select_patient".tr(),
            icon: Icons.person_search,
            color: isDark ? const Color(0xFF217A6B) : const Color(0xFF217A6B),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => SelecteazaPacientScreen(),
              ));
            },
          ),
          const SizedBox(height: 18),
          _MedicHomeCard(
            title: "medicine_alarms".tr(),
            icon: Icons.alarm,
            color: isDark ? const Color(0xFF217A6B) : const Color(0xFF217A6B),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AlarmeMedicScreen(),
              ));
            },
          ),
          const SizedBox(height: 18),
          _MedicHomeCard(
            title: "calls".tr(),
            icon: Icons.call,
            color: isDark ? const Color(0xFF217A6B) : const Color(0xFF217A6B),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ListaApeluriPacientiScreen(),
              ));
            },
          ),
        ],
      ),
    );
  }
}

class _MedicHomeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MedicHomeCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(18),
      color: isDark ? const Color(0xFF232323) : color.withOpacity(0.95),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Profil Medic Modern cu ecran edit dedicat ----
class _MedicProfilePage extends StatefulWidget {
  final Future<void> Function()? onLogout;
  const _MedicProfilePage({Key? key, this.onLogout}) : super(key: key);

  @override
  State<_MedicProfilePage> createState() => _MedicProfilePageState();
}

class _MedicProfilePageState extends State<_MedicProfilePage> {
  String? nume;
  String? prenume;
  String? email;
  String? telefon;
  String? photoUrl;
  String? locatie;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      setState(() {
        nume = data?['nume'] ?? '';
        prenume = data?['prenume'] ?? '';
        email = data?['email'] ?? '';
        telefon = data?['telefon'] ?? '';
        photoUrl = data?['photoUrl'] ?? '';
        locatie = data?['locatie'] ?? '';
        loading = false;
      });
      final parentState = context.findAncestorStateOfType<_MedicHomeScreenState>();
      if (parentState != null) parentState._getMedicName();
    }
  }

  void _goToEditProfile() async {
    final updated = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditMedicProfilePage(
          initialNume: nume ?? '',
          initialPrenume: prenume ?? '',
          initialEmail: email ?? '',
          initialTelefon: telefon ?? '',
          initialPhotoUrl: photoUrl ?? '',
          initialLocatie: locatie ?? '',
        ),
      ),
    );
    if (updated == true) _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (loading) return const Center(child: CircularProgressIndicator());
    final fullName = "${nume ?? ''} ${prenume ?? ''}".trim();
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: isDark ? const Color(0xFF232323) : const Color(0xFF217A6B),
                    backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                        ? NetworkImage(photoUrl!)
                        : null,
                    child: (photoUrl == null || photoUrl!.isEmpty)
                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _goToEditProfile,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF217A6B) : const Color(0xFF217A6B),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(7),
                        child: const Icon(Icons.edit, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                fullName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "doctor".tr(),
                style: TextStyle(fontSize: 17, color: isDark ? Colors.tealAccent : Colors.teal[400]),
              ),
              const SizedBox(height: 18),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
                color: Theme.of(context).cardColor,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.phone, color: isDark ? Colors.tealAccent : const Color(0xFF217A6B)),
                      title: Text(telefon ?? "-", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                    ),
                    ListTile(
                      leading: Icon(Icons.email, color: isDark ? Colors.tealAccent : const Color(0xFF217A6B)),
                      title: Text(email ?? "-", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                    ),
                    ListTile(
                      leading: Icon(Icons.location_on, color: isDark ? Colors.tealAccent : const Color(0xFF217A6B)),
                      title: Text(locatie ?? "-", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              ElevatedButton.icon(
                onPressed: _goToEditProfile,
                icon: const Icon(Icons.edit, color: Colors.white),
                label: Text("edit_profile".tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.tealAccent[700] : const Color(0xFF217A6B),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 38),
              ElevatedButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: Text("logout".tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
