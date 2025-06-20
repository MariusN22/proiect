import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

class SelectMedicScreen extends StatefulWidget {
  const SelectMedicScreen({Key? key}) : super(key: key);

  @override
  State<SelectMedicScreen> createState() => _SelectMedicScreenState();
}

class _SelectMedicScreenState extends State<SelectMedicScreen> {
  String search = "";

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('select_doctor'.tr()),
        backgroundColor: isDark ? const Color(0xFF232323) : const Color(0xFF217A6B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: isDark ? const Color(0xFF18191B) : const Color(0xFFEFF6F4),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.white : Colors.black),
                hintText: 'search_doctor_hint'.tr(),
                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                filled: true,
                fillColor: isDark ? const Color(0xFF232323) : Colors.white,
              ),
              onChanged: (val) => setState(() => search = val.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final rol = data['rol']?.toString().toLowerCase().trim();
                  final status = data['status']?.toString().toLowerCase().trim();
                  final fullName = "${(data['nume'] ?? '').toString().toLowerCase().trim()} ${(data['prenume'] ?? '').toString().toLowerCase().trim()}";
                  return rol == 'medic'
                      && status == 'aprobat'
                      && (search.isEmpty || fullName.contains(search));
                }).toList();

                if (filtered.isEmpty) {
                  return Center(child: Text('no_doctors'.tr(), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final data = filtered[i].data() as Map<String, dynamic>;
                    return ListTile(
                      tileColor: isDark ? const Color(0xFF232323) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: isDark ? Colors.grey[800] : const Color(0xFF217A6B),
                        backgroundImage: (data['pozaProfil'] != null && data['pozaProfil'] != "")
                            ? NetworkImage(data['pozaProfil'])
                            : null,
                        child: (data['pozaProfil'] == null || data['pozaProfil'] == "")
                            ? Icon(Icons.person, size: 30, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        "${data['nume'] ?? ''} ${data['prenume'] ?? ''}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        data['specializare']?.toString().isEmpty ?? true
                            ? 'no_specialization'.tr()
                            : data['specializare'],
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white : Colors.grey[800]),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MedicUserProfileScreen(
                              medicData: data,
                              medicId: filtered[i].id,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ====== Ecranul de profil al medicului + buton Selectează + Înapoi ======
class MedicUserProfileScreen extends StatelessWidget {
  final Map<String, dynamic> medicData;
  final String medicId;

  const MedicUserProfileScreen({
    Key? key,
    required this.medicData,
    required this.medicId,
  }) : super(key: key);

  Future<void> _selectMedic(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_not_authenticated'.tr())),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'medicId': medicId,
        'medicNume': medicData['nume'],
        'medicPrenume': medicData['prenume'],
      });
      // Arată mesajul
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'congrats_doctor_associated'.tr(namedArgs: {
              'name': medicData['nume'] ?? '',
              'surname': medicData['prenume'] ?? ''
            }),
          ),
        ),
      );
      // Navighează la home după 1.5 secunde (pentru ca mesajul să se vadă)
      Future.delayed(const Duration(milliseconds: 1500), () {
        context.go('/homeUser');
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_saving'.tr(namedArgs: {'error': e.toString()})),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('doctor_profile'.tr()),
        backgroundColor: isDark ? const Color(0xFF232323) : const Color(0xFF217A6B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: isDark ? const Color(0xFF18191B) : const Color(0xFFEFF6F4),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: isDark ? Colors.grey[800] : const Color(0xFF217A6B),
              backgroundImage: (medicData['pozaProfil'] != null && medicData['pozaProfil'] != "")
                  ? NetworkImage(medicData['pozaProfil'])
                  : null,
              child: (medicData['pozaProfil'] == null || medicData['pozaProfil'] == "")
                  ? const Icon(Icons.person, size: 40, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 14),
            Text(
              "${medicData['nume'] ?? ''} ${medicData['prenume'] ?? ''}",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              medicData['specializare']?.toString().isEmpty ?? true
                  ? 'no_specialization'.tr()
                  : medicData['specializare'],
              style: TextStyle(
                fontSize: 17,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              medicData['email'] ?? "",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF217A6B),
                minimumSize: const Size(150, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              label: Text("select_this_doctor".tr(), style: const TextStyle(fontSize: 17, color: Colors.white)),
              onPressed: () => _selectMedic(context),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.grey[700] : Colors.grey[600],
                minimumSize: const Size(120, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              label: Text("back".tr(), style: const TextStyle(fontSize: 17, color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
