import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  final String role;
  final String? email;
  const RegisterScreen({super.key, this.role = 'user', this.email});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _userType;
  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();
  final specializationController = TextEditingController();

  File? actImageFile;
  File? medicDocFile;

  bool isLoading = false;
  String errorMessage = '';
  String successMessage = '';

  @override
  void initState() {
    super.initState();
    _userType = widget.role;
    if (widget.email != null) {
      emailController.text = widget.email!;
    }
  }

  Future<void> pickImage(bool isForAct) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Fă o poză'),
              onTap: () async {
                Navigator.of(context).pop();
                final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70);
                if (picked != null) {
                  setState(() {
                    if (isForAct) {
                      actImageFile = File(picked.path);
                    } else {
                      medicDocFile = File(picked.path);
                    }
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Alege din galerie'),
              onTap: () async {
                Navigator.of(context).pop();
                final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (picked != null) {
                  setState(() {
                    if (isForAct) {
                      actImageFile = File(picked.path);
                    } else {
                      medicDocFile = File(picked.path);
                    }
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> uploadImageToFirebase(File file, String path) async {
    final ref = FirebaseStorage.instance.ref(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (actImageFile == null) {
      setState(() => errorMessage = "Încarcă o poză cu actul de identitate!");
      return;
    }
    if (_userType == 'medic' && medicDocFile == null) {
      setState(() => errorMessage = "Încarcă document doveditor pentru medic!");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
      successMessage = '';
    });

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final uid = credential.user!.uid;

      final actUrl = await uploadImageToFirebase(
          actImageFile!, 'acte_identitate/${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      String? docUrl;
      if (_userType == 'medic' && medicDocFile != null) {
        docUrl = await uploadImageToFirebase(
            medicDocFile!, 'documente_medici/${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      }

      final userData = {
        'nume': nameController.text.trim(),
        'prenume': surnameController.text.trim(),
        'rol': _userType,
        'email': emailController.text.trim(),
        'telefon': phoneController.text.trim(),
        'status': _userType == 'medic' ? 'pending' : 'aprobat',
        'act_identitate_url': actUrl,
        if (_userType == 'medic') 'specializare': specializationController.text.trim(),
        if (_userType == 'medic') 'document_doveditor_url': docUrl,
      };

      await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);

      setState(() {
        isLoading = false;
        successMessage = "Cont creat! Verifică emailul sau așteaptă aprobarea dacă ești medic.";
      });

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        context.go('/login');
      });

    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? "Eroare la înregistrare";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Eroare la înregistrare: $e";
        isLoading = false;
      });
    }
  }

  void goToLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fundal cu textura medicală
          Positioned.fill(
            child: Image.asset(
              'assets/bgd.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  children: [
                    // Tab "Log in" / "Sign up"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: goToLogin,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white.withOpacity(0.1),
                            ),
                            child: Text(
                              "LOG IN",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white.withOpacity(0.25),
                            ),
                            child: Text(
                              "SIGN UP",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Logo
                    Image.asset(
                      'assets/logo.png',
                      width: 70,
                      height: 70,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "HealthCare",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Creează-ți contul rapid!",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Card alb cu inputuri — devine transparent
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.30), // TRANSPARENT!
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                hintText: 'Nume',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Numele este obligatoriu' : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: surnameController,
                              decoration: const InputDecoration(
                                hintText: 'Prenume',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Prenumele este obligatoriu' : null,
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              value: _userType,
                              decoration: const InputDecoration(
                                hintText: "Tip utilizator",
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'user',
                                  child: Text("Pacient"),
                                ),
                                DropdownMenuItem(
                                  value: 'medic',
                                  child: Text("Medic"),
                                ),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _userType = val!;
                                  if (_userType != 'medic') medicDocFile = null;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: emailController,
                              decoration: const InputDecoration(
                                hintText: 'Email',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              ),
                              validator: (val) =>
                              val == null || val.isEmpty
                                  ? 'Email obligatoriu'
                                  : !val.contains('@')
                                  ? 'Email invalid'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                hintText: 'Parolă',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              ),
                              validator: (val) => val != null && val.length < 6 ? 'Minim 6 caractere' : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: confirmPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                hintText: 'Confirmă parola',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              ),
                              validator: (val) => val != passwordController.text ? 'Parolele nu coincid' : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: phoneController,
                              decoration: const InputDecoration(
                                hintText: 'Telefon',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (val) => val == null || val.length < 10 ? 'Telefon invalid' : null,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: Icon(
                                      actImageFile == null ? Icons.upload_file : Icons.check_circle,
                                      color: actImageFile == null ? Colors.grey : Colors.green,
                                    ),
                                    label: Text(
                                      actImageFile == null ? 'Încarcă act identitate' : 'Act încărcat!',
                                      style: TextStyle(
                                        color: actImageFile == null ? Colors.black54 : Colors.green,
                                      ),
                                    ),
                                    onPressed: () => pickImage(true),
                                  ),
                                ),
                              ],
                            ),
                            if (_userType == 'medic') ...[
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: specializationController,
                                decoration: const InputDecoration(
                                  hintText: 'Specializare',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                ),
                                validator: (val) => val == null || val.isEmpty ? 'Specializare obligatorie' : null,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: Icon(
                                        medicDocFile == null ? Icons.upload_file : Icons.check_circle,
                                        color: medicDocFile == null ? Colors.grey : Colors.green,
                                      ),
                                      label: Text(
                                        medicDocFile == null ? 'Încarcă doc. doveditor' : 'Document încărcat!',
                                        style: TextStyle(
                                          color: medicDocFile == null ? Colors.black54 : Colors.green,
                                        ),
                                      ),
                                      onPressed: () => pickImage(false),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 20),
                            if (isLoading)
                              const CircularProgressIndicator()
                            else
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFe1395f), // Roz ca în mockup
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: const Text(
                                    'SIGN UP',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            if (errorMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
                              ),
                            if (successMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(successMessage, style: const TextStyle(color: Colors.green)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
