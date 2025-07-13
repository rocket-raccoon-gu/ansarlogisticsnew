import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseExample {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Authentication Examples
  Future<void> signInExample(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('User signed in: ${userCredential.user?.email}');
    } catch (e) {
      print('Sign in error: $e');
    }
  }

  Future<void> signUpExample(String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      print('User created: ${userCredential.user?.email}');
    } catch (e) {
      print('Sign up error: $e');
    }
  }

  // Firestore Examples
  Future<void> saveUserDataExample(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).set(data);
      print('User data saved successfully');
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserDataExample(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Storage Examples
  Future<String?> uploadFileExample(String filePath, String storagePath) async {
    try {
      Reference ref = _storage.ref().child(storagePath);
      await ref.putFile(File(filePath));
      String downloadURL = await ref.getDownloadURL();
      print('File uploaded successfully: $downloadURL');
      return downloadURL;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // Messaging Examples
  Future<String?> getFCMTokenExample() async {
    try {
      String? token = await _messaging.getToken();

      print('FCM Token: $token');
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Analytics Examples
  Future<void> logEventExample(
    String eventName,
    Map<String, dynamic> parameters,
  ) async {
    try {
      await _analytics.logEvent(name: eventName, parameters: parameters);
      print('Analytics event logged: $eventName');
    } catch (e) {
      print('Error logging analytics event: $e');
    }
  }

  // Real-time Database Examples
  Stream<QuerySnapshot> getUsersStreamExample() {
    return _firestore.collection('users').snapshots();
  }

  // Batch Operations Example
  Future<void> batchWriteExample() async {
    try {
      WriteBatch batch = _firestore.batch();

      // Add multiple operations to batch
      DocumentReference userRef = _firestore.collection('users').doc();
      batch.set(userRef, {'name': 'John Doe', 'email': 'john@example.com'});

      DocumentReference orderRef = _firestore.collection('orders').doc();
      batch.set(orderRef, {'userId': userRef.id, 'status': 'pending'});

      // Commit the batch
      await batch.commit();
      print('Batch write completed successfully');
    } catch (e) {
      print('Error in batch write: $e');
    }
  }

  // Query Examples
  Future<List<Map<String, dynamic>>> queryUsersExample() async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'driver')
              .orderBy('createdAt', descending: true)
              .limit(10)
              .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error querying users: $e');
      return [];
    }
  }
}
