// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed-in user (null if not signed in)
  User? get currentUser => _auth.currentUser;

  /// Get Firebase ID token for API authentication
  Future<String?> getIdToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  /// Register with email & password
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Login with email & password
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> logout() async {
    await _auth.signOut();
  }
}
