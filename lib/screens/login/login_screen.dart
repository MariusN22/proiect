import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Importă pluginul FCM:
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  bool isLoading = false;
  bool rememberMe = false;
  bool obscurePassword = true;

  final themeColor = const Color(0xFF217A6B);

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    _loadSavedLogin();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      rememberMe = prefs.getBool('rememberMe') ?? false;
      if (rememberMe) {
        emailController.text = prefs.getString('savedEmail') ?? '';
        passwordController.text = prefs.getString('savedPassword') ?? '';
      }
    });
  }

  Future<void> _saveLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('savedEmail', emailController.text);
      await prefs.setString('savedPassword', passwordController.text);
    } else {
      await prefs.remove('savedEmail');
      await prefs.remove('savedPassword');
    }
    await prefs.setBool('rememberMe', rememberMe);
  }

  // ----------- Salvare FCM Token în Firestore -----------
  Future<void> saveFcmTokenToFirestore(String uid) async {
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': fcmToken,
        });
      }
    } catch (e) {
      // Nu dăm crash dacă nu merge, dar poți loga sau afișa mesaj.
      debugPrint('Eroare la salvarea fcmToken: $e');
    }
  }
  // ------------------------------------------------------

  Future<void> login() async {
    setState(() {
      isLoading = true;
    });
    await _saveLogin();
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nu există acest utilizator!')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }
      final rolUser = userDoc['rol'];
      final statusUser = userDoc['status'] ?? 'aprobat';
      if (rolUser == 'medic' && statusUser != 'aprobat') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Contul de medic nu a fost aprobat de admin!')),
        );
        await FirebaseAuth.instance.signOut();
        setState(() {
          isLoading = false;
        });
        return;
      }

      // --- SALVEAZĂ TOKENUL FCM DUPĂ LOGIN ---
      await saveFcmTokenToFirestore(userCredential.user!.uid);

      if (rolUser == 'user') {
        context.go('/homeUser');
      } else {
        context.go('/medicHome');
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la autentificare: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void goToRegister() {
    context.go('/register');
  }

  void forgotPassword() async {
    if (emailController.text.isEmpty || !emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introdu un email valid pentru resetare!')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email de resetare trimis!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la resetare: $e')),
      );
    }
  }

  // Pentru confirmarea logout-ului poți folosi această funcție oriunde ai nevoie:
  Future<void> confirmLogout(Function() onConfirm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ești sigur că vrei să te deconectezi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Nu'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Da'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textFieldColor = isDark ? Colors.white : themeColor;
    final inputTextColor = isDark ? Colors.white : Colors.black;
    final hintTextColor = isDark ? Colors.white70 : Colors.black54;
    final bgTextField = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.white.withOpacity(0.18);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bgd.png'),
            fit: BoxFit.cover,
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 60,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            child: Text(
                              'LOG IN',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: goToRegister,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            child: Text(
                              'SIGN UP',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Image.asset(
                    'assets/logo.png',
                    width: 240,
                    height: 240,
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.30),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // EMAIL
                    TextField(
                      controller: emailController,
                      style: TextStyle(color: inputTextColor), // <-- text vizibil pe orice temă!
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(color: hintTextColor),
                        filled: true,
                        fillColor: bgTextField,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: themeColor, width: 1.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: themeColor, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.email, color: themeColor),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    // PAROLA
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      style: TextStyle(color: inputTextColor), // <-- text vizibil pe orice temă!
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: TextStyle(color: hintTextColor),
                        filled: true,
                        fillColor: bgTextField,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: themeColor, width: 1.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: themeColor, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.lock, color: themeColor),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: themeColor,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // REMEMBER ME
                    Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          activeColor: themeColor,
                          onChanged: (value) {
                            setState(() => rememberMe = value!);
                          },
                        ),
                        Text(
                          "Remember Me",
                          style: TextStyle(
                            color: textFieldColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: forgotPassword,
                          child: Text(
                            "Ti-ai uitat parola?",
                            style: TextStyle(
                              color: themeColor.withOpacity(0.85),
                              decoration: TextDecoration.underline,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // BUTON LOG IN
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF217A6B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white),
                        )
                            : const Text(
                          'LOG IN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
