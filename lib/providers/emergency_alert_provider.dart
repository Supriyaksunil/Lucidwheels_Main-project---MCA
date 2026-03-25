import 'dart:async';

import 'package:flutter/material.dart';

import '../models/emergency_alert_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class EmergencyAlertProvider extends ChangeNotifier {
  EmergencyAlertProvider({
    FirebaseService? firebaseService,
    NotificationService? notificationService,
  })  : _firebaseService = firebaseService ?? FirebaseService(),
        _notificationService = notificationService ?? NotificationService() {
    unawaited(_notificationService.initializeMessageHandling());
    _incomingSubscription = _notificationService.emergencyAlertStream.listen(
      _handleIncomingAlert,
      onError: (Object error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  final FirebaseService _firebaseService;
  final NotificationService _notificationService;

  StreamSubscription<List<EmergencyAlertRecord>>? _alertsSubscription;
  StreamSubscription<EmergencyAlertRecord>? _incomingSubscription;
  UserModel? _boundUser;
  String _fingerprint = 'signed-out';
  EmergencyAlertRecord? _pendingIncomingAlert;
  List<EmergencyAlertRecord> _recentAlerts = const [];
  EmergencyAlertRecord? _activeAlert;
  bool _isLoading = false;
  String? _error;

  List<EmergencyAlertRecord> get recentAlerts => _recentAlerts;
  EmergencyAlertRecord? get activeAlert => _activeAlert;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void bindUser(UserModel? user) {
    final nextFingerprint = _buildFingerprint(user);
    if (_fingerprint == nextFingerprint) {
      return;
    }

    _fingerprint = nextFingerprint;
    _boundUser = user;
    _error = null;
    _activeAlert = null;
    _recentAlerts = const [];
    _isLoading = false;
    _alertsSubscription?.cancel();
    _alertsSubscription = null;

    if (user == null || user.role != UserRole.emergencyContact) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    _alertsSubscription =
        _firebaseService.streamEmergencyAlertsForUser(user).listen(
      (alerts) {
        _recentAlerts = alerts;
        _isLoading = false;
        if (_pendingIncomingAlert != null) {
          _activeAlert = _pendingIncomingAlert;
          _mergeAlert(_pendingIncomingAlert!);
          _pendingIncomingAlert = null;
        }
        notifyListeners();
      },
      onError: (Object error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
    notifyListeners();
  }

  void showAlert(EmergencyAlertRecord alert) {
    _activeAlert = alert;
    _mergeAlert(alert);
    notifyListeners();
  }

  void dismissActiveAlert() {
    if (_activeAlert == null) {
      return;
    }
    _activeAlert = null;
    notifyListeners();
  }

  void _handleIncomingAlert(EmergencyAlertRecord alert) {
    if (_boundUser?.role != UserRole.emergencyContact) {
      _pendingIncomingAlert = alert;
      return;
    }

    _activeAlert = alert;
    _mergeAlert(alert);
    notifyListeners();
  }

  void _mergeAlert(EmergencyAlertRecord alert) {
    final alerts = [..._recentAlerts];
    final existingIndex =
        alerts.indexWhere((item) => item.alertId == alert.alertId);
    if (existingIndex >= 0) {
      alerts[existingIndex] = alert;
    } else {
      alerts.insert(0, alert);
    }
    alerts.sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
    _recentAlerts = alerts;
  }

  String _buildFingerprint(UserModel? user) {
    if (user == null) {
      return 'signed-out';
    }
    return [user.uid, user.role.storageValue, user.phone.trim()].join('|');
  }

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    _incomingSubscription?.cancel();
    super.dispose();
  }
}
