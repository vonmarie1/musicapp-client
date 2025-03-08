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

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Create user in Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save additional user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> saveRecentSearch(String query) async {
    if (_user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .collection('searches')
            .add({
          'query': query,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error saving search: $e');
      }
    }
  }

  Future<List<String>> getRecentSearches() async {
    List<String> searches = [];

    if (_user != null) {
      try {
        QuerySnapshot querySnapshot = await _firestore
            .collection('users')
            .doc(_user!.uid)
            .collection('searches')
            .orderBy('timestamp', descending: true)
            .limit(5)
            .get();

        searches =
            querySnapshot.docs.map((doc) => doc['query'] as String).toList();
      } catch (e) {
        print('Error getting recent searches: $e');
      }
    }

    return searches;
  }
}
