import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;

import '../models/user_model.dart';
import 'call_service.dart';
import 'firebase_service.dart';
import 'notification_service.dart';
import 'sms_service.dart';

class EmergencyService {
  EmergencyService({
    FirebaseService? firebaseService,
    NotificationService? notificationService,
    CallService? callService,
    SmsService? smsService,
  })  : _firebaseService = firebaseService ?? FirebaseService(),
        _notificationService = notificationService ?? NotificationService(),
        _callService = callService ?? CallService(),
        _smsService = smsService ?? SmsService();

  final FirebaseService _firebaseService;
  final NotificationService _notificationService;
  final CallService _callService;
  final SmsService _smsService;

  Future<void> triggerEmergency({
    required List<EmergencyContact> contacts,
    required UserModel driver,
    required String reason,
    required double lat,
    required double lng,
  }) async {
    if (contacts.isEmpty && driver.linkedFleetIds.isEmpty) {
      return;
    }

    final numbers = contacts
        .map((contact) => contact.phone)
        .map(_normalizePhone)
        .where((number) => number.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final driverName = _resolveDriverName(driver);
    final alertId = 'emergency-${DateTime.now().millisecondsSinceEpoch}';

    try {
      await _firebaseService.createEmergencyAlertRecords(
        alertId: alertId,
        contacts: contacts,
        driver: driver,
        reason: reason,
        lat: lat,
        lng: lng,
      );
    } catch (error) {
      debugPrint('EmergencyService: failed to create alert records: $error');
    }

    final notificationTokens = <String>{};
    try {
      notificationTokens.addAll(
        await _firebaseService.getNotificationTokensForEmergencyContacts(
          contacts,
        ),
      );
    } catch (error) {
      debugPrint(
        'EmergencyService: failed to resolve notification tokens: $error',
      );
    }

    if (EmergencyService.shouldNotifyFleetManagersForReason(reason)) {
      try {
        notificationTokens.addAll(
          await _firebaseService.getNotificationTokensForFleetManagers(
            driver.linkedFleetIds,
          ),
        );
      } catch (error) {
        debugPrint(
          'EmergencyService: failed to resolve fleet manager notification tokens: $error',
        );
      }
    }

    try {
      await _notificationService.sendEmergencyNotification(
        alertId: alertId,
        tokens: notificationTokens.toList(growable: false),
        driverId: driver.uid,
        driverName: driverName,
        reason: reason,
        lat: lat,
        lng: lng,
      );
    } catch (error) {
      debugPrint('EmergencyService: FCM stage failed: $error');
    }

    try {
      await _callService.callEmergencyContacts(numbers);
    } catch (error) {
      debugPrint('EmergencyService: calling stage failed: $error');
    }

    try {
      await _smsService.openSmsFallback(numbers, lat, lng);
    } catch (error) {
      debugPrint('EmergencyService: SMS fallback stage failed: $error');
    }
  }

  @visibleForTesting
  static bool shouldNotifyFleetManagersForReason(String reason) {
    final normalizedReason = reason.trim().toLowerCase();
    return normalizedReason.contains('sos');
  }

  String _resolveDriverName(UserModel driver) {
    final displayName = driver.fullName.trim();
    if (displayName.isNotEmpty) {
      return displayName;
    }
    final email = driver.email.trim();
    if (email.isNotEmpty) {
      return email;
    }
    return 'Driver';
  }

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[^0-9+]'), '');
  }
}
