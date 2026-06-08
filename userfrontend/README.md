# Taxi Nanban - Taxi Booking App

A complete Flutter taxi booking application similar to Uber.

## 🚀 Getting Started

### 1. Prerequisites
- Flutter SDK installed
- Firebase Account
- Google Cloud Console Project (for Google Maps API)

### 2. Firebase Setup
1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/).
2. Add an Android/iOS app to the project.
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
4. Place `google-services.json` in `android/app/`.
5. Place `GoogleService-Info.plist` in `ios/Runner/`.
6. Enable **Authentication** (Email/Password).
7. Enable **Cloud Firestore**.
8. Set Firestore Rules to:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

### 3. Google Maps Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com/).
2. Enable **Maps SDK for Android** and **Maps SDK for iOS**.
3. Create an API Key.
4. Add the API Key to your project:
   - **Android**: In `android/app/src/main/AndroidManifest.xml`:
     ```xml
     <meta-data android:name="com.google.android.geo.API_KEY"
                android:value="YOUR_API_KEY_HERE"/>
     ```
   - **iOS**: In `ios/Runner/AppDelegate.swift`:
     ```swift
     GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
     ```

### 4. Running the App
```bash
flutter pub get
flutter run
```

## 🏗 Project Structure
- `lib/models`: Data models (User, Ride, Driver)
- `lib/services`: Firebase and Location services
- `lib/providers`: State management using Provider
- `lib/screens`: UI Screens
- `lib/widgets`: Reusable UI components
- `lib/utils`: Theme and constants

## ✨ Features
- Firebase Authentication
- Real-time Location Tracking
- Google Maps Integration
- Firestore Database
- Clean Architecture
- Material 3 UI
