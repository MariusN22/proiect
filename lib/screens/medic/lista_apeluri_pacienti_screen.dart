import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'apel_pacient_screen.dart'; // Va trebui creat acest fișier

class ListaApeluriPacientiScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final medicId = FirebaseAuth.instance.currentUser?.uid;

    if (medicId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('calls'.tr()),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        ),
        body: Center(
          child: Text("not_authenticated_medic".tr()),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('calls'.tr()),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('medicId', isEqualTo: medicId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(
                "no_associated_patient".tr(),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final nume = data['nume'] ?? '';
              final prenume = data['prenume'] ?? '';
              final email = data['email'] ?? '';
              final pacientId = docs[i].id;

              return Card(
                color: isDark ? const Color(0xFF232323) : Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                elevation: 2,
                child: ListTile(
                  leading: Icon(Icons.person, color: Theme.of(context).primaryColor),
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
                      builder: (context) => ApelPacientScreen(
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
