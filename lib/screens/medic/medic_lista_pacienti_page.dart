import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart'; // <--- adăugat

/// Varianta pentru TAB bar ("Pacienți" din bara de jos, unde există deja un Scaffold părinte)
class MedicListaPacientiTab extends StatelessWidget {
  void _showPatientDetailsDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('patient_details'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${'name'.tr()}: ${data['nume']} ${data['prenume']}"),
              Text("${'email'.tr()}: ${data['email']}"),
              if (data['telefon'] != null)
                Text("${'phone'.tr()}: ${data['telefon']}")
            ],
          ),
          actions: [
            TextButton(
              child: Text('close'.tr()),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final medicId = FirebaseAuth.instance.currentUser?.uid;
    if (medicId == null) {
      return Center(child: Text("not_authenticated".tr()));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('medicId', isEqualTo: medicId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return Center(child: Text("no_patients".tr()));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final nume = data['nume'] ?? '';
            final prenume = data['prenume'] ?? '';
            final email = data['email'] ?? '';
            return ListTile(
              leading: const Icon(Icons.person, color: Color(0xFF217A6B)),
              title: Text("$nume $prenume"),
              subtitle: Text(email),
              onTap: () => _showPatientDetailsDialog(context, data),
            );
          },
        );
      },
    );
  }
}

/// Varianta pentru PAGINĂ separată (deschisă cu push din meniu/dashboard, cu Scaffold propriu)
class MedicListaPacientiPage extends StatelessWidget {
  void _showPatientDetailsDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('patient_details'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${'name'.tr()}: ${data['nume']} ${data['prenume']}"),
              Text("${'email'.tr()}: ${data['email']}"),
              if (data['telefon'] != null)
                Text("${'phone'.tr()}: ${data['telefon']}")
            ],
          ),
          actions: [
            TextButton(
              child: Text('close'.tr()),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final medicId = FirebaseAuth.instance.currentUser?.uid;
    if (medicId == null) {
      return Scaffold(
        body: Center(child: Text("not_authenticated".tr())),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('patient_list'.tr()),
        backgroundColor: const Color(0xFF217A6B),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('medicId', isEqualTo: medicId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return Center(child: Text("no_patients".tr()));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final nume = data['nume'] ?? '';
              final prenume = data['prenume'] ?? '';
              final email = data['email'] ?? '';
              return ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF217A6B)),
                title: Text("$nume $prenume"),
                subtitle: Text(email),
                onTap: () => _showPatientDetailsDialog(context, data),
              );
            },
          );
        },
      ),
    );
  }
}
