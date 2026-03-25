import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/monitoring_session_model.dart';
import '../services/alert_service.dart';
import '../services/face_detection_service.dart';
import '../services/firebase_service.dart';
import '../services/emergency_service.dart';

class MonitoringProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final FaceDetectionService _faceDetectionService = FaceDetectionService();
  final AlertService _alertService = AlertService();
  final EmergencyService _emergencyService = EmergencyService();

  StreamSubscription? _accelerometerSub;
  Timer? _alertResponseTimer;
  Timer? _sessionSyncTimer;
  DateTime? _highMotionStartedAt;
  DateTime? _lastHighMotionAt;
  final StreamController<void> _safetyConfirmationController =
      StreamController<void>.broadcast();
  MonitoringSession? _currentSession;
  bool _isMonitoring = false;
  DriverState _currentState = DriverState();
  List<AlertEvent> _sessionAlerts = [];
  double _fatigueScore = 0.0;

  DateTime? _lastAlertTriggeredAt;
  AlertType? _lastAlertType;
  AlertType? _activeAlertType;
  String? _activeAlertMessage;
  DateTime? _alertSnoozeUntil;
  bool _hasEscalatedUnacknowledgedAlert = false;
  bool _showAlertOverlay = false;
  bool _isSafetyConfirmationInProgress = false;
  static const int _alertRepeatCooldownSeconds = 6;
  static const Duration _manualAcknowledgeSnooze = Duration(seconds: 10);
  static const Duration _alertResponseTimeout = Duration(seconds: 60);
  static const Duration _sessionSyncInterval = Duration(seconds: 8);
  static const double _baselineGravity = 9.81;
  static const double _accidentMotionThreshold = 8.0;
  static const Duration _accidentMotionPersistDuration = Duration(seconds: 3);
  static const Duration _accidentMotionGapTolerance =
      Duration(milliseconds: 350);

  MonitoringSession? get currentSession => _currentSession;
  bool get isMonitoring => _isMonitoring;
  DriverState get currentState => _currentState;
  List<AlertEvent> get sessionAlerts => _sessionAlerts;
  double get fatigueScore => _fatigueScore;
  bool get isAlertOverlayVisible => _showAlertOverlay;
  AlertType? get activeAlertType => _activeAlertType;
  String? get activeAlertMessage => _activeAlertMessage;

  Stream<DriverState> get driverStateStream =>
      _faceDetectionService.stateStream;
  Stream<AlertType> get alertStream => _alertService.alertStream;
  Stream<void> get safetyConfirmationStream =>
      _safetyConfirmationController.stream;

  MonitoringProvider() {
    _faceDetectionService.stateStream.listen(_onDriverStateChanged);
    _alertService.alertStream.listen(_onAlertTriggered);
  }

  Future<void> startMonitoring(String userId) async {
    if (_isMonitoring) return;

    await _alertService.stopAlert();

    final sessionId = await _firebaseService.createSession(
      MonitoringSession(
        sessionId: '',
        userId: userId,
        startTime: DateTime.now(),
      ),
    );

    _currentSession = MonitoringSession(
      sessionId: sessionId,
      userId: userId,
      startTime: DateTime.now(),
      status: SessionStatus.active,
    );

    _isMonitoring = true;
    _currentState = DriverState();
    _sessionAlerts = [];
    _fatigueScore = 0.0;
    _lastAlertTriggeredAt = null;
    _lastAlertType = null;
    _activeAlertType = null;
    _activeAlertMessage = null;
    _alertSnoozeUntil = null;
    _hasEscalatedUnacknowledgedAlert = false;
    _showAlertOverlay = false;
    _isSafetyConfirmationInProgress = false;
    _highMotionStartedAt = null;
    _lastHighMotionAt = null;
    _cancelAlertResponseTimer();
    _startSessionSyncTimer();

    startAccidentDetection();
    notifyListeners();
  }

  void startAccidentDetection() {
    _accelerometerSub?.cancel();
    _highMotionStartedAt = null;
    _lastHighMotionAt = null;

    _accelerometerSub = accelerometerEventStream().listen((event) {
      if (!_isMonitoring || _hasBlockingAlertFlow) {
        _highMotionStartedAt = null;
        _lastHighMotionAt = null;
        return;
      }

      final now = DateTime.now();
      final totalAcceleration =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final abnormalMotion = (totalAcceleration - _baselineGravity).abs();

      if (abnormalMotion >= _accidentMotionThreshold) {
        _highMotionStartedAt ??= now;
        _lastHighMotionAt = now;

        if (now.difference(_highMotionStartedAt!) >=
            _accidentMotionPersistDuration) {
          _highMotionStartedAt = null;
          _lastHighMotionAt = null;
          showSafetyConfirmation();
        }
        return;
      }

      if (_lastHighMotionAt == null ||
          now.difference(_lastHighMotionAt!) > _accidentMotionGapTolerance) {
        _highMotionStartedAt = null;
        _lastHighMotionAt = null;
      }
    });
  }

  void showSafetyConfirmation() {
    if (!_isMonitoring) {
      return;
    }
    if (_hasBlockingAlertFlow) {
      debugPrint(
        'MonitoringProvider: ignoring accident confirmation because $_activeAlertType is already active',
      );
      _highMotionStartedAt = null;
      _lastHighMotionAt = null;
      return;
    }

    _isSafetyConfirmationInProgress = true;
    _activeAlertType = AlertType.accident;
    _activeAlertMessage =
        'Possible accident detected. Awaiting safety confirmation.';
    _showAlertOverlay = false;
    _cancelAlertResponseTimer();
    _highMotionStartedAt = null;
    _lastHighMotionAt = null;
    notifyListeners();

    if (!_safetyConfirmationController.hasListener) {
      unawaited(reportAccident());
      return;
    }

    _safetyConfirmationController.add(null);
  }

  void processCameraFrame(CameraImage image, InputImageRotation rotation) {
    if (!_isMonitoring) return;
    _faceDetectionService.processImage(image, rotation);
  }

  void _onDriverStateChanged(DriverState state) {
    final inSnoozeWindow = _isInSnoozeWindow;
    _currentState = inSnoozeWindow
        ? state.copyWith(
            isAlert: false,
            isDrowsy: false,
            isDistracted: false,
          )
        : state;

    if (state.isDrowsy) {
      _fatigueScore += 0.1;
      if (_fatigueScore > 1.0) _fatigueScore = 1.0;
    } else {
      _fatigueScore -= 0.05;
      if (_fatigueScore < 0) _fatigueScore = 0;
    }

    if (inSnoozeWindow) {
      _lastAlertType = null;
      _cancelAlertResponseTimer();
      notifyListeners();
      return;
    }

    if (_hasBlockingAlertFlow) {
      if (_showAlertOverlay) {
        _startAlertResponseTimerIfNeeded();
      }
      notifyListeners();
      return;
    }

    final alertDecision = _resolveAlert(state);
    if (alertDecision != null) {
      _triggerAlertWithCooldown(alertDecision);
      _startAlertResponseTimerIfNeeded();
    } else {
      _lastAlertType = null;
      _hasEscalatedUnacknowledgedAlert = false;
      _cancelAlertResponseTimer();
    }

    notifyListeners();
  }

  _AlertDecision? _resolveAlert(DriverState state) {
    if (state.isDrowsy) {
      return const _AlertDecision(
        type: AlertType.drowsiness,
        severity: Severity.high,
        message: 'Eyes closed for more than 3 seconds.',
      );
    }

    if (!state.isFaceDetected && state.isAlert) {
      return const _AlertDecision(
        type: AlertType.distraction,
        severity: Severity.high,
        message: 'Face not detected for more than 5 seconds.',
      );
    }

    if (state.isDistracted && state.isAlert) {
      return const _AlertDecision(
        type: AlertType.distraction,
        severity: Severity.high,
        message: 'Head tilt and low eye visibility for more than 5 seconds.',
      );
    }

    return null;
  }

  void _triggerAlertWithCooldown(_AlertDecision alert) {
    if (_shouldBlockAlertFlow(alert.type)) return;

    final now = DateTime.now();
    if (_lastAlertType == alert.type &&
        _lastAlertTriggeredAt != null &&
        now.difference(_lastAlertTriggeredAt!).inSeconds <
            _alertRepeatCooldownSeconds) {
      return;
    }

    _lastAlertType = alert.type;
    _lastAlertTriggeredAt = now;
    unawaited(
      _triggerAlert(
        alert.type,
        alert.severity,
        details: alert.message,
        activeMessage: alert.message,
      ),
    );
  }

  Future<void> _triggerAlert(
    AlertType type,
    Severity severity, {
    String? details,
    String? activeMessage,
    bool allowTakeover = false,
  }) async {
    if (_shouldBlockAlertFlow(type, allowTakeover: allowTakeover)) return;

    _showAlertOverlay = true;
    _activeAlertType = type;
    _activeAlertMessage = activeMessage ?? _activeAlertMessage;
    notifyListeners();

    final didStart = await _alertService.triggerAlert(
      type,
      severity,
      allowTakeover: allowTakeover,
    );
    if (!didStart) {
      return;
    }

    if (_currentSession != null) {
      final alert = AlertEvent(
        alertId: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: _currentSession!.sessionId,
        userId: _currentSession!.userId,
        type: type,
        alertTime: DateTime.now(),
        severity: severity,
        details: details,
      );

      _sessionAlerts.add(alert);
      await _firebaseService.addAlert(alert);

      _currentSession!.totalAlerts = _sessionAlerts.length;
      await _syncCurrentSessionMetrics();
      notifyListeners();
    }
  }

  void _onAlertTriggered(AlertType type) {
    debugPrint('MonitoringProvider: alert triggered -> $type');
  }

  Future<void> acknowledgeCurrentAlert({
    Duration snoozeDuration = _manualAcknowledgeSnooze,
  }) async {
    _alertSnoozeUntil = DateTime.now().add(snoozeDuration);
    _lastAlertTriggeredAt = null;
    _lastAlertType = null;
    _activeAlertType = null;
    _activeAlertMessage = null;

    _currentState = _currentState.copyWith(
      isAlert: false,
      isDrowsy: false,
      isDistracted: false,
    );
    _hasEscalatedUnacknowledgedAlert = false;
    _showAlertOverlay = false;
    _isSafetyConfirmationInProgress = false;
    _highMotionStartedAt = null;
    _lastHighMotionAt = null;
    _cancelAlertResponseTimer();

    await _alertService.stopAlert();
    notifyListeners();
  }

  Future<void> clearTransientState() async {
    _alertSnoozeUntil = null;
    _lastAlertTriggeredAt = null;
    _lastAlertType = null;
    _activeAlertType = null;
    _activeAlertMessage = null;
    _currentState = DriverState();
    _fatigueScore = 0.0;
    _hasEscalatedUnacknowledgedAlert = false;
    _showAlertOverlay = false;
    _isSafetyConfirmationInProgress = false;
    _highMotionStartedAt = null;
    _lastHighMotionAt = null;
    _cancelAlertResponseTimer();
    _cancelSessionSyncTimer();
    await _alertService.stopAlert();
    notifyListeners();
  }

  Future<void> stopMonitoring() async {
    if (!_isMonitoring || _currentSession == null) return;

    _currentSession!.endTime = DateTime.now();
    _currentSession!.durationMinutes =
        DateTime.now().difference(_currentSession!.startTime).inMinutes;
    _currentSession!.status = SessionStatus.completed;
    _currentSession!.fatigueScore = _fatigueScore;

    await _firebaseService.updateSession(_currentSession!);

    await _alertService.stopAlert();
    _accelerometerSub?.cancel();
    _accelerometerSub = null;
    _isSafetyConfirmationInProgress = false;
    _highMotionStartedAt = null;
    _lastHighMotionAt = null;
    _cancelAlertResponseTimer();
    _cancelSessionSyncTimer();

    _isMonitoring = false;
    _currentSession = null;
    await clearTransientState();
  }

  Future<void> reportAccident({
    bool playSound = false,
    String reason = 'Possible accident detected by LucidWheels.',
  }) async {
    if (_currentSession == null) return;
    _isSafetyConfirmationInProgress = false;
    _showAlertOverlay = false;
    _activeAlertType = AlertType.accident;
    _activeAlertMessage = 'Emergency escalation in progress.';
    _cancelAlertResponseTimer();
    _highMotionStartedAt = null;
    _lastHighMotionAt = null;
    notifyListeners();

    await _alertService.triggerEmergencyAlert(
      playSound: playSound,
      allowTakeover: true,
    );
    final position = await _getCurrentPositionSafe();
    await _notifyEmergencyContacts(
      position: position,
      reason: reason,
    );
    await _logIncident(
      severity: Severity.critical,
      description: 'Accident detected at ${_formatLocation(position)}',
      position: position,
    );

    _currentSession!.isAccidentDetected = true;
    _currentSession!.status = SessionStatus.emergency;
    await _firebaseService.updateSession(_currentSession!);
    notifyListeners();
  }

  Future<void> handleSafetyConfirmationResult(bool isSafe) async {
    _isSafetyConfirmationInProgress = false;
    _highMotionStartedAt = null;
    _lastHighMotionAt = null;

    if (isSafe) {
      _activeAlertType = null;
      _activeAlertMessage = null;
      _showAlertOverlay = false;
      notifyListeners();
      return;
    }

    if (!_isMonitoring || _currentSession == null) return;

    await reportAccident();
  }

  Future<void> _handleUnacknowledgedAlert() async {
    if (_currentSession == null || _hasEscalatedUnacknowledgedAlert) return;

    _hasEscalatedUnacknowledgedAlert = true;

    await _triggerAlert(
      AlertType.accident,
      Severity.critical,
      details: 'Alert was not acknowledged for 60 seconds.',
      activeMessage:
          'No response for 60 seconds.\nEmergency escalation in progress.',
      allowTakeover: true,
    );
    final position = await _getCurrentPositionSafe();

    await _notifyEmergencyContacts(
      position: position,
      reason: 'Driver did not acknowledge drowsiness alert within 60 seconds.',
    );

    await _logIncident(
      severity: Severity.high,
      description:
          'Unacknowledged drowsiness alert for 60 seconds at ${_formatLocation(position)}',
      position: position,
    );
  }

  Future<Position?> _getCurrentPositionSafe() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('MonitoringProvider: failed to get location: $e');
      return null;
    }
  }

  Future<void> _notifyEmergencyContacts({
    required Position? position,
    required String reason,
  }) async {
    if (_currentSession == null) return;

    final userData =
        await _firebaseService.getUserData(_currentSession!.userId);
    if (userData == null || userData.emergencyContacts.isEmpty) {
      debugPrint('MonitoringProvider: no emergency contacts found');
      return;
    }

    final latitude = position?.latitude ?? 0.0;
    final longitude = position?.longitude ?? 0.0;

    try {
      await _emergencyService.triggerEmergency(
        contacts: userData.emergencyContacts,
        driver: userData,
        reason: reason,
        lat: latitude,
        lng: longitude,
      );
    } catch (error) {
      debugPrint(
        'MonitoringProvider: emergency escalation failed for "$reason": $error',
      );
    }
  }

  Future<void> _logIncident({
    required Severity severity,
    required String description,
    required Position? position,
  }) async {
    if (_currentSession == null) return;

    final incident = IncidentReport(
      incidentId: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: _currentSession!.sessionId,
      userId: _currentSession!.userId,
      incidentTime: DateTime.now(),
      severity: severity,
      description: description,
      latitude: position?.latitude,
      longitude: position?.longitude,
    );

    await _firebaseService.addIncident(incident);
  }

  String _formatLocation(Position? position) {
    if (position == null) return 'unknown location';
    return '${position.latitude},${position.longitude}';
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
    _cancelAlertResponseTimer();
    _cancelSessionSyncTimer();
    _safetyConfirmationController.close();
    _faceDetectionService.dispose();
    _alertService.dispose();
    super.dispose();
  }

  bool get _isInSnoozeWindow =>
      _alertSnoozeUntil != null && DateTime.now().isBefore(_alertSnoozeUntil!);

  @visibleForTesting
  static bool hasActiveAlertFlow({
    required bool isSafetyConfirmationInProgress,
    required bool showAlertOverlay,
    required AlertType? activeAlertType,
  }) {
    return isSafetyConfirmationInProgress ||
        showAlertOverlay ||
        activeAlertType != null;
  }

  @visibleForTesting
  static bool shouldBlockIncomingAlert({
    required bool isMonitoring,
    required bool isSafetyConfirmationInProgress,
    required bool showAlertOverlay,
    required AlertType? activeAlertType,
    bool allowTakeover = false,
  }) {
    if (!isMonitoring) {
      return true;
    }
    if (allowTakeover) {
      return false;
    }
    return hasActiveAlertFlow(
      isSafetyConfirmationInProgress: isSafetyConfirmationInProgress,
      showAlertOverlay: showAlertOverlay,
      activeAlertType: activeAlertType,
    );
  }

  bool get _hasBlockingAlertFlow => MonitoringProvider.hasActiveAlertFlow(
        isSafetyConfirmationInProgress: _isSafetyConfirmationInProgress,
        showAlertOverlay: _showAlertOverlay,
        activeAlertType: _activeAlertType,
      );

  bool _shouldBlockAlertFlow(
    AlertType type, {
    bool allowTakeover = false,
  }) {
    final shouldBlock = MonitoringProvider.shouldBlockIncomingAlert(
      isMonitoring: _isMonitoring,
      isSafetyConfirmationInProgress: _isSafetyConfirmationInProgress,
      showAlertOverlay: _showAlertOverlay,
      activeAlertType: _activeAlertType,
      allowTakeover: allowTakeover,
    );
    if (!shouldBlock || allowTakeover) {
      return shouldBlock;
    }
    if (_isSafetyConfirmationInProgress) {
      debugPrint(
        'MonitoringProvider: ignoring $type because accident confirmation is active',
      );
      return true;
    }
    debugPrint(
      'MonitoringProvider: ignoring $type because $_activeAlertType is already active',
    );
    return true;
  }

  void _startAlertResponseTimerIfNeeded() {
    if (_alertResponseTimer != null || _hasEscalatedUnacknowledgedAlert) {
      return;
    }
    _alertResponseTimer = Timer(_alertResponseTimeout, () {
      _alertResponseTimer = null;
      if (!_isMonitoring ||
          !_showAlertOverlay ||
          _hasEscalatedUnacknowledgedAlert) {
        return;
      }
      unawaited(_handleUnacknowledgedAlert());
    });
  }

  void _cancelAlertResponseTimer() {
    _alertResponseTimer?.cancel();
    _alertResponseTimer = null;
  }

  void _startSessionSyncTimer() {
    _cancelSessionSyncTimer();
    _sessionSyncTimer = Timer.periodic(_sessionSyncInterval, (_) {
      unawaited(_syncCurrentSessionMetrics());
    });
  }

  void _cancelSessionSyncTimer() {
    _sessionSyncTimer?.cancel();
    _sessionSyncTimer = null;
  }

  Future<void> _syncCurrentSessionMetrics() async {
    if (!_isMonitoring || _currentSession == null) return;

    final elapsedMinutes =
        DateTime.now().difference(_currentSession!.startTime).inMinutes;
    _currentSession!
      ..durationMinutes = elapsedMinutes
      ..fatigueScore = _fatigueScore
      ..totalAlerts = _sessionAlerts.length;

    try {
      await _firebaseService.updateSession(_currentSession!);
    } catch (e) {
      debugPrint('MonitoringProvider: failed session sync: $e');
    }
  }
}

class _AlertDecision {
  final AlertType type;
  final Severity severity;
  final String message;

  const _AlertDecision({
    required this.type,
    required this.severity,
    required this.message,
  });
}
