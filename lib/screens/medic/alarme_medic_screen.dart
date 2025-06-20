import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'calendar_alarm_screen.dart'; // <--- importă fișierul nou creat!

class AlarmeMedicScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final medicId = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (medicId == null) {
      return Scaffold(
        appBar: AppBar(title: Text("medicine_alarms".tr())),
        body: Center(child: Text("not_authenticated".tr())),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("medicine_alarms".tr()),
        backgroundColor: isDark ? const Color(0xFF232323) : const Color(0xFF217A6B),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('medicId', isEqualTo: medicId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text("no_patients".tr()));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final pacientId = docs[i].id;
              final nume = data['nume'] ?? '';
              final prenume = data['prenume'] ?? '';
              final email = data['email'] ?? '';

              return Material(
                color: isDark ? const Color(0xFF232323) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 3,
                child: ListTile(
                  leading: const Icon(Icons.person, color: Color(0xFF217A6B)),
                  title: Text(
                    "$nume $prenume",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    email,
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => CalendarAlarmScreen(
                        pacientId: pacientId,
                        nume: nume,
                        prenume: prenume,
                      ),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
