# Android Configuration - Veloce Express

Veloce Express is Android-only.

## Package

Use this package id:

```gradle
applicationId "com.yourcompany.veloceexpress"
minSdkVersion 23
targetSdkVersion 34
multiDexEnabled true
```

## Permissions

Add these to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.CALL_PHONE"/>
```

## Firebase

Put the Android Firebase file here:

```text
android/app/google-services.json
```

`lib/firebase_options.dart` is Android-only. Replace its placeholder values by running:

```bash
flutterfire configure --platforms=android
```

Firebase Storage is not required. Driver vehicle photos are compressed and saved
as Base64 fields in the user document:

```text
users/{uid}.vehiclePhotoBase64
users/{uid}.vehiclePhotoContentType
```

## Maps

No Google Maps API key is required.

Veloce Express uses `flutter_map` + OpenStreetMap tiles:

```text
https://tile.openstreetmap.org/{z}/{x}/{y}.png
```

Keep `INTERNET` permission enabled so map tiles can load.

## Notifications

Veloce Express uses local Android notifications with the system default sound.
No Cloud Functions are required.

The app listens to unread Firestore documents here:

```text
notifications/{notificationId}
```

Each notification should include:

```text
userId
orderId
type
title
body
read: false
createdAt
```

This works while the app is open or running in the background. Fully closed-app
push notifications require a backend such as Cloud Functions, which is not
enabled for this project.
