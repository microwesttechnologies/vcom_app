import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _backgroundLocalNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _backgroundChatChannel =
    AndroidNotificationChannel(
      'chat_messages',
      'Mensajes de chat',
      description: 'Notificaciones push del modulo de chat',
      importance: Importance.high,
    );

bool _backgroundNotificationsReady = false;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb || Platform.isWindows) return;
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  await _ensureBackgroundNotificationsConfigured();
  await _showBackgroundNotification(message);
}

@pragma('vm:entry-point')
Future<void> _ensureBackgroundNotificationsConfigured() async {
  if (_backgroundNotificationsReady) return;

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await _backgroundLocalNotifications.initialize(initSettings);

  final androidPlatform = _backgroundLocalNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await androidPlatform?.createNotificationChannel(_backgroundChatChannel);
  await _backgroundLocalNotifications
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);
  _backgroundNotificationsReady = true;
}

@pragma('vm:entry-point')
Future<void> _showBackgroundNotification(RemoteMessage message) async {
  final data = Map<String, dynamic>.from(message.data);
  final title =
      message.notification?.title ??
      (data['title']?.toString().trim().isNotEmpty == true
          ? data['title'].toString().trim()
          : 'Nuevo mensaje');
  final body =
      message.notification?.body ??
      (data['body']?.toString().trim().isNotEmpty == true
          ? data['body'].toString().trim()
          : (data['content'] ?? 'Tienes un mensaje nuevo').toString());

  await _backgroundLocalNotifications.show(
    _resolveNotificationId(data),
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _backgroundChatChannel.id,
        _backgroundChatChannel.name,
        channelDescription: _backgroundChatChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: jsonEncode(data),
  );
}

int _resolveNotificationId(Map<String, dynamic> data) {
  final conversationId = (data['conversation_id'] ?? '').toString().trim();
  if (conversationId.isEmpty) {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }
  return conversationId.hashCode;
}
