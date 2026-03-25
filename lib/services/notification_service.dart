import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/emergency_alert_model.dart';
import 'firebase_service.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final AudioPlayer _emergencyAlertPlayer = AudioPlayer();
  final StreamController<EmergencyAlertRecord> _emergencyAlertController =
      StreamController<EmergencyAlertRecord>.broadcast();

  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _tokenBoundUserId;
  bool _messageHandlingInitialized = false;

  Stream<EmergencyAlertRecord> get emergencyAlertStream =>
      _emergencyAlertController.stream;

  Future<void> initializeMessageHandling() async {
    if (_messageHandlingInitialized) {
      return;
    }
    _messageHandlingInitialized = true;

    try {
      await _messaging.setAutoInitEnabled(true);
    } catch (error) {
      debugPrint(
        'NotificationService: failed to initialize message handling: $error',
      );
    }

    FirebaseMessaging.onMessage.listen(
      (message) => unawaited(_handleRemoteMessage(message)),
      onError: (Object error) {
        debugPrint('NotificationService: foreground message failed: $error');
      },
    );

    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => unawaited(_handleRemoteMessage(message)),
      onError: (Object error) {
        debugPrint('NotificationService: open-app message failed: $error');
      },
    );

    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        await _handleRemoteMessage(initialMessage);
      }
    } catch (error) {
      debugPrint('NotificationService: initial message failed: $error');
    }
  }

  Future<void> sendEmergencyNotification({
    required String alertId,
    required List<String> tokens,
    required String driverId,
    required String driverName,
    required String reason,
    required double lat,
    required double lng,
  }) async {
    final deduplicatedTokens = tokens
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (deduplicatedTokens.isEmpty) {
      return;
    }

    try {
      await _functions.httpsCallable('sendEmergencyNotification').call({
        'alertId': alertId,
        'tokens': deduplicatedTokens,
        'driverId': driverId,
        'driverName': driverName,
        'reason': reason,
        'lat': lat,
        'lng': lng,
        'triggeredAt': DateTime.now().toIso8601String(),
      });
    } catch (error) {
      debugPrint(
        'NotificationService: failed to send emergency notification: $error',
      );
    }
  }

  Future<void> syncCurrentUserToken(String uid, {String? phone}) async {
    try {
      await _messaging.setAutoInitEnabled(true);
    } catch (error) {
      debugPrint('NotificationService: failed to enable auto init: $error');
    }

    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (error) {
      debugPrint(
        'NotificationService: notification permission request failed: $error',
      );
    }

    try {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (error) {
      debugPrint(
        'NotificationService: foreground presentation setup failed: $error',
      );
    }

    try {
      final token = await _messaging.getToken();
      await _firebaseService.updateUserNotificationToken(
        uid,
        token,
        phone: phone,
      );
    } catch (error) {
      debugPrint('NotificationService: failed to sync FCM token: $error');
    }

    if (_tokenBoundUserId == uid && _tokenRefreshSubscription != null) {
      return;
    }

    await _tokenRefreshSubscription?.cancel();
    _tokenBoundUserId = uid;
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (token) async {
        try {
          await _firebaseService.updateUserNotificationToken(
            uid,
            token,
            phone: phone,
          );
        } catch (error) {
          debugPrint(
            'NotificationService: failed to refresh FCM token: $error',
          );
        }
      },
      onError: (Object error) {
        debugPrint('NotificationService: token refresh listener error: $error');
      },
    );
  }

  Future<void> clearCurrentUserToken(String uid, {String? phone}) async {
    try {
      await _firebaseService.updateUserNotificationToken(
        uid,
        null,
        phone: phone,
      );
    } catch (error) {
      debugPrint('NotificationService: failed to clear FCM token: $error');
    }

    if (_tokenBoundUserId == uid) {
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;
      _tokenBoundUserId = null;
    }
  }

  Future<void> playIncomingEmergencyAlertSound() async {
    try {
      await _emergencyAlertPlayer.stop();
      await _emergencyAlertPlayer.setReleaseMode(ReleaseMode.stop);
      await _emergencyAlertPlayer.setVolume(1.0);
      if (kIsWeb) {
        await _emergencyAlertPlayer.play(UrlSource('assets/sounds/alert.mp3'));
      } else {
        await _emergencyAlertPlayer.play(AssetSource('sounds/alert.mp3'));
      }
    } catch (error) {
      debugPrint('NotificationService: alert sound playback failed: $error');
    }
  }

  Future<void> _handleRemoteMessage(RemoteMessage message) async {
    final alert = _parseEmergencyAlert(message);
    if (alert == null) {
      return;
    }

    await playIncomingEmergencyAlertSound();
    _emergencyAlertController.add(alert);
  }

  EmergencyAlertRecord? _parseEmergencyAlert(RemoteMessage message) {
    final data = message.data;
    final type = data['type']?.toString().trim() ?? '';
    if (type != 'emergency_alert') {
      return null;
    }

    final lat = double.tryParse(data['lat']?.toString() ?? '') ?? 0.0;
    final lng = double.tryParse(data['lng']?.toString() ?? '') ?? 0.0;
    final rawDriverName = data['driverName']?.toString().trim() ?? '';
    final driverName = rawDriverName.isEmpty ? 'Driver' : rawDriverName;
    final rawMessage = data['message']?.toString().trim() ?? '';
    final messageText = rawMessage.isNotEmpty
        ? rawMessage
        : 'Emergency detected for $driverName';
    final reason = data['reason']?.toString().trim() ?? '';
    final rawMapUrl = data['mapUrl']?.toString().trim() ?? '';
    final mapUrl =
        rawMapUrl.isEmpty ? 'https://maps.google.com/?q=$lat,$lng' : rawMapUrl;
    final rawAlertId = data['alertId']?.toString().trim() ?? '';
    final rawDriverId = data['driverId']?.toString().trim() ?? '';
    final rawTriggeredAt = data['triggeredAt']?.toString().trim() ?? '';

    return EmergencyAlertRecord(
      alertId: rawAlertId.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : rawAlertId,
      driverId: rawDriverId,
      driverName: driverName,
      message: messageText,
      reason: reason,
      mapUrl: mapUrl,
      latitude: lat,
      longitude: lng,
      triggeredAt: DateTime.tryParse(rawTriggeredAt) ?? DateTime.now(),
    );
  }
}
