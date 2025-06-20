import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';

class MedicProfileScreen extends StatefulWidget {
  const MedicProfileScreen({super.key});

  @override
  State<MedicProfileScreen> createState() => _MedicProfileScreenState();
}

class _MedicProfileScreenState extends State<MedicProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  String? nume, prenume, email, photoUrl;
  final specializareController = TextEditingController();
  final locatieController = TextEditingController();
  final detaliiController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMedicData();
  }

  Future<void> _loadMedicData() async {
    setState(() => isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      setState(() {
        nume = data?['nume'] ?? '';
        prenume = data?['prenume'] ?? '';
        email = data?['email'] ?? '';
        specializareController.text = data?['specializare'] ?? '';
        locatieController.text = data?['locatie'] ?? '';
        detaliiController.text = data?['detalii'] ?? '';
        photoUrl = data?['photoUrl'];
        isLoading = false;
      });
    }
  }

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final XFile? picked =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => isLoading = true);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final file = File(picked.path);
      final ref = FirebaseStorage.instance.ref('profile_photos/$uid.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'photoUrl': url,
      });

      setState(() {
        photoUrl = url;
        isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'specializare': specializareController.text.trim(),
      'locatie': locatieController.text.trim(),
      'detalii': detaliiController.text.trim(),
    });
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('profile_saved'.tr())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themePrimary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('doctor_profile'.tr()),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: isDark
                        ? const Color(0xFF232323)
                        : themePrimary.withOpacity(0.18),
                    backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                        ? NetworkImage(photoUrl!)
                        : null,
                    child: photoUrl == null || photoUrl!.isEmpty
                        ? const Icon(Icons.person, size: 50, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: CircleAvatar(
                      backgroundColor: themePrimary,
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: _pickProfilePhoto,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              // NUME & PRENUME (readonly)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${nume ?? ""} ${prenume ?? ""}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 21,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(email ?? '',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  )),
              const SizedBox(height: 22),
              TextFormField(
                controller: specializareController,
                decoration: InputDecoration(
                  labelText: 'specialization'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'complete_specialization'.tr()
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: locatieController,
                decoration: InputDecoration(
                  labelText: 'location'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'complete_location'.tr()
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: detaliiController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'description'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themePrimary,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('save'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
