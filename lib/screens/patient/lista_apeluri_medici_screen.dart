import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

import 'apel_medic_screen.dart';

class ListaApeluriMediciScreen extends StatelessWidget {
  const ListaApeluriMediciScreen({Key? key}) : super(key: key);

  Future<Map<String, dynamic>?> _getMediculAles() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = userDoc.data();
    final medicId = data?['medicId'];
    if (medicId == null || medicId == '') return null;
    final medicDoc = await FirebaseFirestore.instance.collection('users').doc(medicId).get();
    if (!medicDoc.exists) return null;
    final medicData = medicDoc.data();
    return {
      'medicId': medicId,
      'nume': medicData?['nume'] ?? '',
      'prenume': medicData?['prenume'] ?? '',
      'email': medicData?['email'] ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text("calls".tr()),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getMediculAles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                "no_associated_doctor".tr(),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }
          final medic = snapshot.data!;
          final nume = medic['nume'] ?? '';
          final prenume = medic['prenume'] ?? '';
          final email = medic['email'] ?? '';
          final medicId = medic['medicId'] ?? '';

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            children: [
              Card(
                color: isDark ? const Color(0xFF232323) : Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 2,
                child: ListTile(
                  leading: Icon(Icons.medical_services, color: Theme.of(context).primaryColor),
                  title: Text(
                    "$nume $prenume",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    email,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ApelMedicScreen(
                        medicId: medicId,
                        nume: nume,
                        prenume: prenume,
                      ),
                    ));
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
