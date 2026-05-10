# Firebase Cloud Messaging

The Android app and backend are prepared for FCM:

- The app requests notification permission.
- The app saves each user's FCM token in `users/{uid}.fcmTokens`.
- The app displays foreground FCM messages through the same local notification channel and selected sound.
- The app keeps the Firestore listener as an in-app fallback.
- The backend exposes the callable Cloud Function `sendNotification` in `functions/index.js`.

The app must not send FCM messages directly with server credentials. Notification delivery goes through the trusted Firebase Cloud Function, which uses Firebase Admin SDK on the backend.

## Cloud Function

`sendNotification` requires an authenticated caller and accepts:

```text
toUserId: string
title: string
body: string
orderId?: string
type?: string
```

The function reads `users/{toUserId}.fcmTokens`, sends a high-priority multicast notification, and returns success/failure counts plus failed token details.

Authorization is enforced server-side:

- Admin users can notify any approved user.
- Order participants can notify another participant on the same order when `orderId` is supplied.
- A driver who already created a bid can send the `bid_received` notification to the order client.

## Deploy

Install function dependencies, then deploy Firebase Functions and Firestore configuration:

```powershell
cd functions
npm install
cd ..
firebase deploy --only functions,firestore:rules,firestore:indexes
```

Cloud Functions for Firebase usually requires the Firebase Blaze plan.
