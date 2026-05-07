import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  NotificationService({
    FirebaseFirestore? firestore,
    FlutterLocalNotificationsPlugin? plugin,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _defaultChannel = AndroidNotificationChannel(
    'veloce_express_alerts_custom_v1',
    'Veloce Express alerts',
    description: 'General Veloce Express notifications.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    sound: RawResourceAndroidNotificationSound('message_sound'),
  );

  static const _channels = <String, AndroidNotificationChannel>{
    'direct_request': AndroidNotificationChannel(
      'veloce_express_direct_request_v1',
      'Delivery requests',
      description: 'New delivery requests.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('whatsapp_notification'),
    ),
    'chat_message': AndroidNotificationChannel(
      'veloce_express_chat_v1',
      'Trip chat',
      description: 'Messages between client and driver.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('iphone_sms'),
    ),
    'delivered': AndroidNotificationChannel(
      'veloce_express_delivered_v1',
      'Delivery completed',
      description: 'Delivery completion notifications.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('delivered_message'),
    ),
    'trip_started': AndroidNotificationChannel(
      'veloce_express_trip_started_v1',
      'Trip started',
      description: 'Active trip notifications.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('sms_android'),
    ),
    'support_reply': AndroidNotificationChannel(
      'veloce_express_support_v1',
      'Support replies',
      description: 'Replies from support.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('notice11'),
    ),
  };

  final FirebaseFirestore _firestore;
  final FlutterLocalNotificationsPlugin _plugin;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notificationsSub;
  StreamSubscription<RemoteMessage>? _fcmForegroundSub;
  StreamSubscription<String>? _tokenRefreshSub;
  bool _initializedSnapshot = false;
  String _preferredSound = 'message_sound';
  int _notificationId = 1000;

  void setPreferredSound(String sound) {
    _preferredSound = sound;
  }

  Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_defaultChannel);
    for (final channel in _channels.values) {
      await android?.createNotificationChannel(channel);
    }
    await android?.requestNotificationsPermission();
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _fcmForegroundSub = FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      final title =
          notification?.title ?? message.data['title'] ?? 'Veloce Express';
      final body = notification?.body ?? message.data['body'] ?? '';
      show(
        title: title,
        body: body,
        type: message.data['type'] as String?,
        payload: message.data['orderId'] as String?,
      );
    });
  }

  Future<void> show({
    required String title,
    required String body,
    String? type,
    String? payload,
  }) async {
    final channel = _channels[type] ?? _defaultChannel;
    final preferredChannel = AndroidNotificationChannel(
      'veloce_express_user_sound_$_preferredSound',
      'Selected notification sound',
      description: 'User selected Veloce Express notification sound.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound(_preferredSound),
    );
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(preferredChannel);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        preferredChannel.id,
        preferredChannel.name,
        channelDescription: channel.description,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: preferredChannel.sound,
        enableVibration: true,
        category: AndroidNotificationCategory.message,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _plugin.show(
      _notificationId++,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> watchUserNotifications(String userId) async {
    await stopWatching();
    await registerFcmToken(userId);
    _initializedSnapshot = false;
    _notificationsSub = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(25)
        .snapshots()
        .listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        if (!_initializedSnapshot && change.doc.metadata.hasPendingWrites) {
          continue;
        }
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data();
        if (data == null) continue;
        if (data['read'] == true) continue;

        final title = data['title'] as String? ?? 'Veloce Express';
        final body = data['body'] as String? ?? '';
        await show(
          title: title,
          body: body,
          type: data['type'] as String?,
          payload: data['orderId'] as String?,
        );

        await change.doc.reference.update({
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      _initializedSnapshot = true;
    }, onError: (Object error, StackTrace stackTrace) {
      debugPrint('Notification listener error: $error');
    });
  }

  Future<void> registerFcmToken(String userId) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) {
        _firestore.collection('users').doc(userId).update({
          'fcmTokens': FieldValue.arrayUnion([newToken]),
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      },
      onError: (Object error) {
        debugPrint('FCM token refresh error: $error');
      },
    );
  }

  Future<void> stopWatching() async {
    await _notificationsSub?.cancel();
    await _tokenRefreshSub?.cancel();
    _notificationsSub = null;
    _tokenRefreshSub = null;
    _initializedSnapshot = false;
  }

  Future<void> dispose() async {
    await _fcmForegroundSub?.cancel();
    await stopWatching();
  }
}
