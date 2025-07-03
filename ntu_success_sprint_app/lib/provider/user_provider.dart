import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser; // Holds the current authenticated user

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Constructor: Immediately set up the listener when the provider is created
  UserProvider() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _currentUser = user; // Update the internal user state
      notifyListeners(); // Notify all listening widgets
      print('UserProvider: Auth state changed. User: $_currentUser');
    });
  }

  // Optional: Methods for login/logout if you want to centralize them
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      // _currentUser will be updated automatically by the authStateChanges listener
    } on FirebaseAuthException catch (e) {
      // Handle login errors (e.g., weak password, email already in use)
      print('Login error: $e');
      rethrow; // Re-throw to allow UI to handle specific errors
    } catch (e) {
      print('An unexpected error occurred: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      // _currentUser will be set to null automatically by the authStateChanges listener
    } catch (e) {
      print('Logout error: $e');
      rethrow;
    }
  }
}
