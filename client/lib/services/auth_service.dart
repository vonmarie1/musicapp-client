import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isLoading = false;
  Timer? _emailVerificationTimer;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;

      // If user exists and email is not verified, start verification check
      if (user != null && !user.emailVerified) {
        _startEmailVerificationCheck();
      }

      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isEmailVerified => _user?.emailVerified ?? false;

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

      // Start checking for email verification
      _startEmailVerificationCheck();

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
  Future<UserCredential?> signIn(
      String email, String password, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // Check if email is verified
      await userCredential.user?.reload();
      User? updatedUser = _auth.currentUser;

      if (updatedUser != null && !updatedUser.emailVerified) {
        // If email is not verified, start checking for verification
        _startEmailVerificationCheck();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Please verify your email to continue. Check your inbox.')),
        );
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

  // Start checking for email verification
  void _startEmailVerificationCheck() {
    // Cancel any existing timer
    _emailVerificationTimer?.cancel();

    // Check every 5 seconds if the email has been verified
    _emailVerificationTimer =
        Timer.periodic(Duration(seconds: 5), (timer) async {
      // Reload user to get latest email verification status
      await _user?.reload();
      _user = _auth.currentUser;

      if (_user != null && _user!.emailVerified) {
        // Email is verified, stop checking
        timer.cancel();
        _emailVerificationTimer = null;

        // Notify listeners that email is verified
        notifyListeners();
      }
    });
  }

  // Manually check if email is verified
  Future<bool> checkEmailVerified() async {
    if (_user == null) return false;

    await _user!.reload();
    _user = _auth.currentUser;
    notifyListeners();
    return _user?.emailVerified ?? false;
  }

  // Send verification email
  Future<void> sendVerificationEmail(BuildContext context) async {
    if (_user != null && !_user!.emailVerified) {
      try {
        await _user!.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Verification email sent. Please check your inbox.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error sending verification email: ${e.toString()}')),
        );
      }
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

      // Cancel email verification timer if active
      _emailVerificationTimer?.cancel();
      _emailVerificationTimer = null;

      await _auth.signOut();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(
      String email, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email')),
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Error sending password reset email: ${e.toString()}')),
      );
      rethrow;
    }
  }

  @override
  void dispose() {
    _emailVerificationTimer?.cancel();
    super.dispose();
  }
}
