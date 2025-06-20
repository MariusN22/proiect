import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:easy_localization/easy_localization.dart';

class EditMedicProfilePage extends StatefulWidget {
  final String initialNume;
  final String initialPrenume;
  final String initialEmail;
  final String initialTelefon;
  final String initialPhotoUrl;
  final String initialLocatie;

  const EditMedicProfilePage({
    Key? key,
    required this.initialNume,
    required this.initialPrenume,
    required this.initialEmail,
    required this.initialTelefon,
    required this.initialPhotoUrl,
    required this.initialLocatie,
  }) : super(key: key);

  @override
  State<EditMedicProfilePage> createState() => _EditMedicProfilePageState();
}

class _EditMedicProfilePageState extends State<EditMedicProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController numeController;
  late TextEditingController prenumeController;
  late TextEditingController emailController;
  late TextEditingController telefonController;
  late TextEditingController locatieController;
  String? photoUrl;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    numeController = TextEditingController(text: widget.initialNume);
    prenumeController = TextEditingController(text: widget.initialPrenume);
    emailController = TextEditingController(text: widget.initialEmail);
    telefonController = TextEditingController(text: widget.initialTelefon);
    locatieController = TextEditingController(text: widget.initialLocatie);
    photoUrl = widget.initialPhotoUrl;
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
    // parola inainte de a salva
    final success = await _showPasswordDialogAndReauth();
    if (success != true) return;

    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'nume': numeController.text.trim(),
      'prenume': prenumeController.text.trim(),
      // email nu e modificabil!
      'telefon': telefonController.text.trim(),
      'locatie': locatieController.text.trim(),
    });
    setState(() => isLoading = false);
    Navigator.of(context).pop(true);
  }

  // POP-UP pentru parolă și reautentificare
  Future<bool> _showPasswordDialogAndReauth() async {
    final TextEditingController passController = TextEditingController();
    bool isLoadingPass = false;
    String? error;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('confirm_password'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('to_save_changes_enter_password'.tr()),
                TextField(
                  controller: passController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'password'.tr(),
                    errorText: error,
                  ),
                ),
                if (isLoadingPass) const SizedBox(height: 18),
                if (isLoadingPass) const CircularProgressIndicator(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: isLoadingPass
                    ? null
                    : () async {
                  setState(() => isLoadingPass = true);
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    final cred = EmailAuthProvider.credential(
                      email: user!.email!,
                      password: passController.text,
                    );
                    await user.reauthenticateWithCredential(cred);
                    setState(() => isLoadingPass = false);
                    Navigator.pop(context, true);
                  } on FirebaseAuthException catch (_) {
                    setState(() {
                      isLoadingPass = false;
                      error = 'wrong_password'.tr();
                    });
                  }
                },
                child: Text('confirm'.tr()),
              ),
            ],
          ),
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('edit_profile'.tr()),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Theme.of(context).primaryColor,
        ),
      ),
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
                        : Theme.of(context).primaryColor.withOpacity(0.18),
                    backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
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
                      backgroundColor: Theme.of(context).primaryColor,
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: _pickProfilePhoto,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: numeController,
                decoration: InputDecoration(
                  labelText: 'name'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'required_field'.tr()
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: prenumeController,
                decoration: InputDecoration(
                  labelText: 'surname'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'required_field'.tr()
                    : null,
              ),
              const SizedBox(height: 16),
              // --- LOCAȚIE ---
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
                controller: telefonController,
                decoration: InputDecoration(
                  labelText: 'phone'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // EMAIL nemodificabil!
              TextFormField(
                controller: emailController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'email'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  helperText: "".tr(),
                ),
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
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
