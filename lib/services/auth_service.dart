import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Future<UserCredential> signIn(String email, String pass) {
    return _auth.signInWithEmailAndPassword(email: email, password: pass);
  }

  Future<void> signOut() => _auth.signOut();

  User? get currentUser => _auth.currentUser;
}
