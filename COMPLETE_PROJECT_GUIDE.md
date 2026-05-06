# Veloce Express — Complete Project Guide (All Sprints)

## Architecture Overview

```
lib/
├── core/
│   ├── constants/       app_colors, app_text_styles (theme)
│   ├── errors/          failures.dart
│   ├── router/          app_router.dart  ← final version
│   ├── services/        location_service.dart
│   └── utils/           validators.dart
│
├── data/
│   ├── models/          user_model, order_model, bid_model
│   └── repositories/    auth_impl, order_impl, tracking_impl
│
├── domain/
│   ├── entities/        user_entity, order_entity, bid_entity
│   └── repositories/    auth_repo, order_repo, tracking_repo
│
└── presentation/
    ├── auth/            login, signup, pending, email_verify  ← Sprint 1
    ├── client/          home, create_order, order_detail      ← Sprint 2
    ├── driver/          home, place_bid                       ← Sprint 2
    ├── tracking/        active_trip                           ← Sprint 3
    ├── admin/           dashboard (approvals/orders/users)    ← Sprint 4
    └── shared/          widgets (button, field, overlay)
```

---

## Complete Setup Checklist

### Step 1 — Firebase Project
- [ ] Create project at console.firebase.google.com
- [ ] Enable **Email/Password** Authentication
- [ ] Create **Firestore** database (Production mode)
- [ ] Enable **Cloud Messaging** (FCM)
- [ ] Android notifications are local system notifications driven by Firestore `notifications`

### Step 2 — FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_PROJECT_ID
# → generates lib/firebase_options.dart
```

### Step 3 — Security Rules
Deploy the included rules and indexes:
```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

### Step 4 — Firestore Indexes
```bash
firebase deploy --only firestore:indexes
```
(use the JSON from `NATIVE_CONFIG.md`)

### Step 5 — OpenStreetMap
No Google Maps API key is required. Veloce Express uses `flutter_map` with OpenStreetMap tiles.

### Step 6 — Run
```bash
flutter pub get
flutter run
```

---

## Full User Flow

```
┌─────────────────────────────────────────────────────────┐
│                     SPRINT 1: AUTH                       │
├─────────────────────────────────────────────────────────┤
│  Signup → Email Verify → Pending Approval → Home         │
│  (Admin approves manually in Firestore or Admin tab)     │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                  SPRINT 2: BIDDING                       │
├─────────────────────────────────────────────────────────┤
│  Client: Create Order (pin map → form → post)            │
│  Driver: See job feed (real-time) → Place Bid            │
│  Client: See bids → Accept / Reject                      │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│                SPRINT 3: LIVE TRACKING                   │
├─────────────────────────────────────────────────────────┤
│  Driver: GPS stream → Firestore → Client map updates     │
│  Both:   See live map, route polyline, call button       │
│  Driver: "Confirm Delivery" → order = delivered          │
│  Client: Rating sheet (1-5 stars + comment)              │
│          → Driver rating updated via Firestore tx        │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│               SPRINT 4: ADMIN DASHBOARD                  │
├─────────────────────────────────────────────────────────┤
│  Tab 1 — Approvals:  View vehicle photo → Approve/Reject │
│  Tab 2 — Orders:     Filter by status, live stream       │
│  Tab 3 — Users:      Toggle approval, view ratings       │
└─────────────────────────────────────────────────────────┘
```

---

## BLoC State Machines

### AuthBloc
```
AuthInitial
  └─ AuthCheckRequested
       ├─ AuthLoading
       ├─ AuthUnauthenticated     → /login
       ├─ AuthEmailUnverified     → /verify-email  (polls every 5s)
       ├─ AuthPendingApproval     → /pending        (polls every 10s)
       └─ AuthAuthenticated       → /client|driver|admin home
```

### OrderBloc
```
OrderInitial
  ├─ OrderCreateRequested  → OrderProcessing → OrderCreated
  ├─ OrderWatchOpenOrders  → OpenOrdersLoaded (stream)
  ├─ OrderWatchClientOrders→ ClientOrdersLoaded (stream)
  ├─ OrderWatchBids        → BidsLoaded (stream)
  ├─ OrderBidPlaceRequested→ OrderProcessing → BidPlaced
  ├─ OrderBidAccepted      → OrderProcessing → BidActionSuccess
  └─ OrderBidRejected      → BidActionSuccess
```

### TrackingBloc
```
TrackingInitial
  ├─ TrackingStartTrip     → GPS stream starts → TrackingActive
  │                           (pushes location to Firestore every 10m)
  ├─ TrackingWatchDriver   → Firestore stream → TrackingActive
  │                           (client sees driver moving)
  ├─ TrackingCompleteDelivery → TrackingDelivered
  │                              (driver goes home, client rates)
  └─ TrackingRateDriver    → TrackingRated → client home
```

---

## Key Architecture Decisions

| Decision | Why |
|---|---|
| Security Rules as primary guard | UI-only auth is bypassable; Rules enforce at DB level |
| `isApproved` write-protected | Drivers can't self-approve; only Admin role can write it |
| Atomic batch writes for bids | Order status + bid count update in one transaction = no race conditions |
| Stream subscriptions cancelled in `close()` | Prevents memory leaks across screen navigation |
| `distanceFilter: 10` in GPS | Reduces Firestore writes; only updates when driver moves 10m |
| Incremental rating average | No need to store all ratings; O(1) update per completed trip |
| GoRouter redirect over BLoC navigation | Declarative; impossible to reach protected routes via deep link |
| Firestore offline persistence | Orders/bids cached locally; app works on poor connections |

---

## Navigating to Active Trip

```dart
// From OrderDetailScreen (after accepting bid):
context.go('/active-trip', extra: {
  'order':      acceptedOrder,
  'otherParty': driverUser,   // fetch driver by driverId
});

// From DriverHomeScreen (after bid accepted notification):
context.go('/active-trip', extra: {
  'order':      order,
  'otherParty': clientUser,   // fetch client by clientId
});
```

---

## What's Production-Ready

✅ Firebase Auth + Email verification  
✅ Admin approval gatekeeper (3-layer security)  
✅ Driver vehicle photo upload + admin review  
✅ Real-time order feed (Firestore streams)  
✅ Atomic bid placement + auto-reject losing bids  
✅ Live GPS tracking (10m filter, Firestore sync)  
✅ Call button (url_launcher)  
✅ Veloce Express trip confirmation flow  
✅ Star rating with incremental average update  
✅ Admin dashboard (approvals, orders, users)  
✅ Offline persistence (Firestore cache)  
✅ FCM token saved per user  
✅ Memory-safe BLoCs (all streams cancelled)  
✅ GoRouter auth guards (redirect-based)  

## What to Add Before App Store

- [ ] OpenStreetMap geocoding integration, for example Nominatim
- [ ] OpenStreetMap routing integration, for example OSRM
- [ ] Optional closed-app push backend later, if a paid or external backend is available
- [ ] Stripe / payment gateway integration
- [ ] In-app chat between client and driver
- [ ] Order history with earnings chart (admin)
- [ ] Driver earnings screen
