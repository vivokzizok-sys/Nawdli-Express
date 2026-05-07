# Firebase Cloud Messaging

The Android app is prepared for FCM:

- It requests notification permission.
- It saves each user's FCM token in `users/{uid}.fcmTokens`.
- It displays foreground FCM messages through the same local notification channel and selected sound.
- It keeps the Firestore listener as an in-app fallback.

Important: the app must not send FCM messages directly. A trusted backend must read the notification event and send the FCM message with Firebase Admin SDK or the FCM HTTP v1 API. Put server credentials only on that backend, never in Flutter.

Options:

- Cloud Functions for Firebase: simplest, but generally requires the Blaze plan.
- A small private server/VPS: can use Firebase Admin SDK and your Firebase service account.
- A local admin script: useful for testing, not reliable for production.

For now, app-side FCM is ready; the remaining production step is the secure sender backend.
