import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';

// Import corect relativ!
import '../patient/edit_patient_profile_page.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  String? nume, prenume, email, telefon, locatie, photoUrl;
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
        locatie = data?['locatie'] ?? '';
        photoUrl = data?['photoUrl'] ?? '';
        loading = false;
      });
    }
  }

  void _goToEditProfile() async {
    final updated = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditPatientProfilePage(
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
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
                  "user".tr(),
                  style: TextStyle(fontSize: 17, color: isDark ? Colors.tealAccent : Colors.teal[400]),
                ),
                const SizedBox(height: 18),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
                  color: Theme.of(context).cardColor,
                  child: Column(
                    children: [
                      if ((telefon ?? "").isNotEmpty)
                        ListTile(
                          leading: Icon(Icons.phone, color: isDark ? Colors.tealAccent : const Color(0xFF217A6B)),
                          title: Text(telefon ?? "-", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                        ),
                      if ((email ?? "").isNotEmpty)
                        ListTile(
                          leading: Icon(Icons.email, color: isDark ? Colors.tealAccent : const Color(0xFF217A6B)),
                          title: Text(email ?? "-", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                        ),
                      if ((locatie ?? "").isNotEmpty)
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
                // Butonul de logout a fost eliminat!
              ],
            ),
          ),
        ),
      ),
    );
  }
}
