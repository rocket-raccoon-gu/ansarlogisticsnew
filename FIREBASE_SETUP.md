# Firebase Integration Setup Guide

This guide will help you set up Firebase in your Flutter project.

## Prerequisites

1. **Firebase Console Account**: Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. **Flutter SDK**: Make sure you have Flutter installed and configured
3. **Android Studio / Xcode**: For platform-specific configurations

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Create a project" or "Add project"
3. Enter your project name (e.g., "Ansar Logistics")
4. Enable Google Analytics (optional but recommended)
5. Choose your Analytics account or create a new one
6. Click "Create project"

## Step 2: Add Firebase to Your App

### For Android:

1. In Firebase Console, click on the Android icon (</>) to add an Android app
2. Enter your Android package name: `com.ansar.ansarlogistics`
3. Enter app nickname: "Ansar Logistics"
4. Click "Register app"
5. Download the `google-services.json` file
6. Place the file in `android/app/google-services.json`
7. Click "Next" and follow the setup instructions

### For iOS:

1. In Firebase Console, click on the iOS icon to add an iOS app
2. Enter your iOS bundle ID: `com.ansar.ansarlogistics.ansarlogisticsnew`
3. Enter app nickname: "Ansar Logistics"
4. Click "Register app"
5. Download the `GoogleService-Info.plist` file
6. Place the file in `ios/Runner/GoogleService-Info.plist`
7. Click "Next" and follow the setup instructions

## Step 3: Enable Firebase Services

In your Firebase Console, enable the following services:

### Authentication
1. Go to Authentication > Sign-in method
2. Enable Email/Password authentication
3. Optionally enable other providers (Google, Facebook, etc.)

### Firestore Database
1. Go to Firestore Database
2. Click "Create database"
3. Choose "Start in test mode" for development
4. Select a location for your database

### Cloud Storage
1. Go to Storage
2. Click "Get started"
3. Choose "Start in test mode" for development
4. Select a location for your storage

### Cloud Messaging
1. Go to Cloud Messaging
2. The service is automatically enabled

### Analytics
1. Go to Analytics
2. The service is automatically enabled

## Step 4: Install Dependencies

Run the following command to install Firebase dependencies:

```bash
flutter pub get
```

## Step 5: Configure Firebase Services

### Update Configuration Files

Replace the placeholder values in the configuration files:

1. **Android**: Update `android/app/google-services.json` with your actual Firebase configuration
2. **iOS**: Update `ios/Runner/GoogleService-Info.plist` with your actual Firebase configuration

### Update Package Names

Make sure the package names in your configuration files match your actual app:

- Android: `com.ansar.ansarlogistics`
- iOS: `com.ansar.ansarlogistics.ansarlogisticsnew`

## Step 6: Test Firebase Integration

Run your app and check the console for Firebase initialization messages:

```
Firebase initialized successfully
User granted permission: authorized
FCM Token: [your-fcm-token]
```

## Step 7: Security Rules

### Firestore Security Rules

Update your Firestore security rules in the Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read and write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to read public data
    match /public/{document=**} {
      allow read: if request.auth != null;
    }
  }
}
```

### Storage Security Rules

Update your Storage security rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow users to upload files to their own folder
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Usage Examples

### Authentication

```dart
// Sign in
await FirebaseAuthService().signInWithEmailAndPassword(email, password);

// Sign up
await FirebaseAuthService().createUserWithEmailAndPassword(email, password);

// Sign out
await FirebaseAuthService().signOut();
```

### Firestore

```dart
// Save user data
await FirebaseAuthService().saveUserData({
  'name': 'John Doe',
  'email': 'john@example.com',
  'role': 'driver',
});

// Get user data
Map<String, dynamic>? userData = await FirebaseAuthService().getUserData(userId);
```

### Storage

```dart
// Upload file
String? downloadURL = await FirebaseService.storage
    .ref()
    .child('users/$userId/profile.jpg')
    .putFile(file)
    .then((task) => task.ref.getDownloadURL());
```

### Messaging

```dart
// Get FCM token
String? token = await FirebaseService.messaging.getToken();



// Listen to messages
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('Got a message: ${message.notification?.title}');
});
```

## Troubleshooting

### Common Issues

1. **"No Firebase App '[DEFAULT]' has been created"**
   - Make sure Firebase is initialized in `main.dart`
   - Check that configuration files are in the correct locations

2. **"Permission denied" errors**
   - Check your Firestore/Storage security rules
   - Ensure the user is authenticated

3. **"Network error"**
   - Check your internet connection
   - Verify Firebase project settings

4. **iOS build errors**
   - Make sure `GoogleService-Info.plist` is added to the Xcode project
   - Check that the bundle ID matches

### Debug Tips

1. Enable Firebase debug logging:
   ```dart
   FirebaseFirestore.instance.settings = Settings(
     persistenceEnabled: true,
     cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
   );
   ```

2. Check Firebase Console for error logs

3. Use Firebase CLI for local development:
   ```bash
   npm install -g firebase-tools
   firebase login
   firebase init
   ```

## Next Steps

1. **Implement User Authentication**: Use Firebase Auth for user sign-in/sign-up
2. **Store User Data**: Use Firestore to store user profiles and app data
3. **Push Notifications**: Implement FCM for push notifications
4. **File Upload**: Use Firebase Storage for file uploads
5. **Analytics**: Track user behavior with Firebase Analytics

## Support

For more information, visit:
- [Firebase Flutter Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com)
- [Flutter Documentation](https://flutter.dev/docs) 

