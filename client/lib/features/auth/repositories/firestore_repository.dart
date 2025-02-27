import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DocumentSnapshot<Map<String, dynamic>>> fetchUser(
      String userId) async {
    return await _firestore.collection('users').doc(userId).get();
  }

  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final querySnapshot = await _firestore.collection('users').get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }
}
