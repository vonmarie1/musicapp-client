import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isLoading = false;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  // Sign up with email and password
  Future<UserCredential> signUp(
      String name, String email, String password, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Create user with email and password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'photoURL': null,
      });

      // Send verification email
      await userCredential.user?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Verification email sent. Please check your inbox.')),
      );

      _isLoading = false;
      notifyListeners();
      return userCredential;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-up failed: ${e.toString()}')),
      );
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signIn(
      String email, String password, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      await _user?.reload();
      if (_user != null && !_user!.emailVerified) {
        await _auth.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Email not verified. Please check your inbox.')),
        );
        throw Exception('Email not verified');
      }

      _isLoading = false;
      notifyListeners();
      return userCredential;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
      rethrow;
    }
  }

  // Check if email is verified
  Future<bool> checkEmailVerified() async {
    await _user?.reload();
    _user = _auth.currentUser;
    notifyListeners();
    return _user?.emailVerified ?? false;
  }

  // Send verification email
  Future<void> sendVerificationEmail() async {
    if (_user != null && !_user!.emailVerified) {
      await _user!.sendEmailVerification();
    }
  }

  // Update user profile
  Future<void> updateProfile({
    required String displayName,
    String? photoURL,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_user != null) {
        // Update Firebase Auth profile
        await _user!.updateDisplayName(displayName);
        if (photoURL != null) {
          await _user!.updatePhotoURL(photoURL);
        }

        // Update Firestore document
        await _firestore.collection('users').doc(_user!.uid).update({
          'name': displayName,
          if (photoURL != null) 'photoURL': photoURL,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Refresh user data
        await _user!.reload();
        _user = _auth.currentUser;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Change password
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_user != null && _user!.email != null) {
        // Re-authenticate user
        AuthCredential credential = EmailAuthProvider.credential(
          email: _user!.email!,
          password: currentPassword,
        );

        await _user!.reauthenticateWithCredential(credential);

        // Change password
        await _user!.updatePassword(newPassword);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Delete user account
  Future<void> deleteAccount(String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_user != null && _user!.email != null) {
        // Re-authenticate user
        AuthCredential credential = EmailAuthProvider.credential(
          email: _user!.email!,
          password: password,
        );

        await _user!.reauthenticateWithCredential(credential);

        // Delete Firestore document
        await _firestore.collection('users').doc(_user!.uid).delete();

        // Delete user account
        await _user!.delete();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signOut();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
