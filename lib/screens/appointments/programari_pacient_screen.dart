import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgramariPacientScreen extends StatefulWidget {
  const ProgramariPacientScreen({super.key});

  @override
  State<ProgramariPacientScreen> createState() => _ProgramariPacientScreenState();
}

class _ProgramariPacientScreenState extends State<ProgramariPacientScreen> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Programările mele")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('programari')
            .where('pacientId', isEqualTo: user!.uid)
            .orderBy('dataProgramare', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Nu aveți programări.'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'în așteptare';
              final date = (data['dataProgramare'] as Timestamp).toDate();
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(
                  "${data['motiv'] ?? 'Fără motiv'}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}\nStatus: $status",
                ),
                trailing: status == "în așteptare"
                    ? IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection('programari')
                        .doc(docs[i].id)
                        .delete();
                  },
                )
                    : null,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text("Programează vizită"),
      ),
    );
  }

  void _showAddDialog(BuildContext context) async {
    DateTime? dataSelectata;
    TimeOfDay? oraSelectata;
    String motiv = "";
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Programează o vizită"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: "Motiv programare"),
                  validator: (v) => v == null || v.isEmpty ? "Obligatoriu" : null,
                  onChanged: (v) => motiv = v,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(dataSelectata == null
                      ? "Alege data"
                      : "${dataSelectata!.day}/${dataSelectata!.month}/${dataSelectata!.year}"),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setStateDialog(() => dataSelectata = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: Text(oraSelectata == null
                      ? "Alege ora"
                      : "${oraSelectata!.hour.toString().padLeft(2, '0')}:${oraSelectata!.minute.toString().padLeft(2, '0')}"),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setStateDialog(() => oraSelectata = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Anulează"),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              child: const Text("Trimite"),
              onPressed: () async {
                if (formKey.currentState!.validate() &&
                    dataSelectata != null &&
                    oraSelectata != null) {
                  final programareDateTime = DateTime(
                    dataSelectata!.year,
                    dataSelectata!.month,
                    dataSelectata!.day,
                    oraSelectata!.hour,
                    oraSelectata!.minute,
                  );
                  final user = FirebaseAuth.instance.currentUser;
                  final pacientDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .get();
                  final medicId = pacientDoc.data()?['medicId'];
                  if (medicId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Selectează mai întâi un medic!")));
                    return;
                  }
                  await FirebaseFirestore.instance.collection('programari').add({
                    'pacientId': user.uid,
                    'medicId': medicId,
                    'motiv': motiv,
                    'dataProgramare': programareDateTime,
                    'status': "în așteptare",
                    'timestampCerere': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
