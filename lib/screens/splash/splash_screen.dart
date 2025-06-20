import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;

    if (user == null) {
      context.go('/login');
      return;
    }
    // Verificăm rolul userului din Firestore
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = userDoc.data();
      final rolUser = data?['rol'] ?? 'user';
      if (rolUser == 'medic') {
        context.go('/medicHome');
      } else {
        context.go('/homeUser');
      }
    } catch (e) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fundalul cu textura medicală
          Positioned.fill(
            child: Image.asset(
              'assets/bgd.png',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 160,
                  height: 200,
                ),
                const SizedBox(height: 5),
                const Text(
                  'HealthCare',
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '“Grija ta, prioritatea noastră”',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
