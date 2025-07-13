import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'notification_service.dart';

class FirebaseService {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseMessaging get messaging => FirebaseMessaging.instance;
  static FirebaseAnalytics get analytics => FirebaseAnalytics.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;

  // Initialize Firebase
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      print('Firebase initialized successfully');

      // Initialize notification service
      await NotificationService.initialize();

      // Request notification permissions
      await _requestNotificationPermissions();

      // Configure messaging
      await _configureMessaging();
    } catch (e) {
      print('Error initializing Firebase: $e');
    }
  }

  // Request notification permissions
  static Future<void> _requestNotificationPermissions() async {
    try {
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('User granted permission: ${settings.authorizationStatus}');
    } catch (e) {
      print('Error requesting notification permissions: $e');
    }
  }

  // Configure Firebase Messaging
  static Future<void> _configureMessaging() async {
    try {
      // Get FCM token
      String? token = await messaging.getToken();
      print('FCM Token: $token');

      // Handle token refresh
      messaging.onTokenRefresh.listen((newToken) {
        print('FCM Token refreshed: $newToken');
        // TODO: Send new token to your server
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print(
            'Message also contained a notification: ${message.notification}',
          );
          _showNotification(message);
        }
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Notification tapped: ${message.data}');
        _handleNotificationTap(message);
      });

      // Check if app was opened from notification
      RemoteMessage? initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        print('App opened from notification: ${initialMessage.data}');
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      print('Error configuring messaging: $e');
    }
  }

  // Get current user
  static User? get currentUser => auth.currentUser;

  // Check if user is signed in
  static bool get isSignedIn => currentUser != null;

  // Sign out
  static Future<void> signOut() async {
    try {
      await auth.signOut();
      print('User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Get FCM token
  static Future<String?> getFCMToken() async {
    try {
      String? token = await messaging.getToken();
      String? accessToken = await getAccessToken();
      print('AccessToken: $accessToken');
      print('FCM Token: $token');
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Test notification
  static Future<void> testNotification() async {
    await NotificationService.showNotification(
      title: 'Test Notification',
      body: 'This is a test notification from Ansar Logistics',
      payload: 'test',
    );
  }

  // Show notification
  static void _showNotification(RemoteMessage message) {
    print('Showing notification: ${message.notification?.title}');
    print('Notification body: ${message.notification?.body}');

    // Show local notification
    NotificationService.showNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  // Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    print('Handling notification tap: ${message.data}');

    // Handle different notification types based on data
    if (message.data.containsKey('type')) {
      String type = message.data['type'];
      switch (type) {
        case 'order':
          // Navigate to order details
          print('Navigate to order: ${message.data['order_id']}');
          break;
        case 'message':
          // Navigate to messages
          print('Navigate to messages');
          break;
        default:
          print('Unknown notification type: $type');
      }
    }

    // TODO: Implement navigation logic based on your app structure
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

Future<String> getAccessToken() async {
  final serviceAccountJson = {
    "type": "service_account",
    "project_id": "ah-market-5ab28",
    "private_key_id": "5642c3e3db6707f875af8cba7e78cead92b1b5a1",
    "private_key":
        "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDggC67Xcdnvaiq\nC+NhKu/BEvnOv8RUodobf+Gtt2qnnhVv3TM1aqfXQX2qaYHG75fggeqXHieNTKyp\n1pIONnCmWYhk8zGT/a8byD0bZt4E+FBGln4gcXYdWzYdyO+qUPsZFYRDAW9/yd5p\n03qpAo1nO4/HKtEbgpwh1CyEj1ZWVavMxSBNrzpQLZttjLp0OPAeCrv3UciK5xid\nOvKqPaUorYxGKgJjaaXh0ly1rRfWuQwzuH1XoyIp+S8m1/nEbPR5W85/Qv2KvI9m\nTiXq8M7PJ1jne41ypwHYoKwqgGy8nfK7FIocQCiH1SwVCfVX1bYYOW/F9TndKPV+\n2wNaVRTlAgMBAAECggEABIn67HjMUDNR2f6UwJFJj7uYqb7Gd88nNaV7prf0qsJo\nbwxQ1Hx4u8JgwIWb7kkRMAAYb7uF4Wi5fNMnGL9lPnTpdTufYBjK6nK0OLlbrEv6\nz86LoaI4fZiG1BxoPYKNtkCoJs/zJ1byxGyffxPtvXaepPToezOEN9NOQ0H/7h/2\n9wnHW6g0t/vAay8q2ne+zYmuKB3LuTl5MPuD083Pk5KXwqYrxHKrW0G7nxdJvxzA\ngdAH1KXWqN3SXXVH2XRmZfFqUlYhCMqTTRnRscqXoMN6J2DYvUz/1hbYH2jynLVV\nNg9BVCQPtcc9U3ENOEzSb7zxCrz246/YB7FhSFEm6QKBgQDvy4pnHj6rtgBD4mKn\nLh+mCellYl9HKeCuW7XHyp1/fgv+ueYPqALUXkR+92j0X8PawCwtb1qxFvWtjXz/\ncfpj/sQpAOERbeAjU6dNPxi5RbYqQyOhQgAbfwWoCrH6Y2hp2vesFypykCW3aP7Z\nM/eQ6nfFowkE4xfIUCuRgDGUPQKBgQDvrAyPqMIlnYsOn0LvmFCd/bVM7vKFw3cK\nale2QzqrhedaGHX2WjER7vwo8l9UIuwFRX1aSP1Nb+f+BcFQzbs+Z7VXck2Xj4o3\np0NhOuyLbpSaPDwiSSuMUkGuYgwkmIVnptBmw92ikV+vOAAwvOdMHjvy8GDbFnpc\nYPS9eTSFyQKBgQCxJK3jq4Ykl1juzSiP1BTxNdVDXj6AdcFTTNCm/VkIO/dkf7Qi\n0Lz2YYU8Pk08ahpnWRvJnL9kn09ynFlA49RTVntWxx19IKw5rKyk9f2vsH34Do0d\nrYIizd1B3FTKYfFacbYRXTOwWihiq5/ImQlD9tHwIJajE5gYFJF69TarCQKBgG0e\negGWJf6WQc+Adys6v8mOz1Kdn9GC8tnNHO4gob+iEXkVle95lMnDcw75eqmF1Mt5\nnd7TSHBPOOKQoDk30b5R3WBY7DbK5XT9NFI6T6QTzpiCQCakBa23bawFe93Vizdr\n3YpMNsZjRZsy9fM6rlwbj9PF2XMmQsN4aTUyz9TxAoGBAOxe2pEjjvgR4Ll58lsP\nVq9K+u9HKAVDM32feUm+KIDILy5bPTb+6HjEcsEHF567GuCga3wciX9wk7Cxh8ko\nFkTJuUdDORqVDOkYgw2hl+bcOSKQsuem2ve13vmdq2mKhF4x8DGM4lckegvxUWyM\nziqB8bQJYo8UedjNiX99gR6W\n-----END PRIVATE KEY-----\n",
    "client_email":
        "firebase-adminsdk-a6zp5@ah-market-5ab28.iam.gserviceaccount.com",
    "client_id": "107685861698938940303",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url":
        "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-a6zp5%40ah-market-5ab28.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com",
  };

  List<String> scopes = [
    "https://www.googleapis.com/auth/userinfo.email",
    "https://www.googleapis.com/auth/firebase.messaging",
    "https://www.googleapis.com/auth/firebase.database",
  ];

  http.Client client = await auth.clientViaServiceAccount(
    auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
    scopes,
  );

  auth.AccessCredentials credentials = await auth
      .obtainAccessCredentialsViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        scopes,
        client,
      );

  client.close();

  return credentials.accessToken.data;
}
