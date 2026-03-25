enum SessionStatus { active, completed, emergency }

enum AlertType { drowsiness, distraction, accident, fatigue }

enum Severity { low, medium, high, critical }

class MonitoringSession {
  final String sessionId;
  final String userId;
  final DateTime startTime;
  DateTime? endTime;
  int durationMinutes;
  int totalAlerts;
  SessionStatus status;
  double fatigueScore;
  bool isAccidentDetected;

  MonitoringSession({
    required this.sessionId,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.durationMinutes = 0,
    this.totalAlerts = 0,
    this.status = SessionStatus.active,
    this.fatigueScore = 0.0,
    this.isAccidentDetected = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'totalAlerts': totalAlerts,
      'status': status.toString().split('.').last,
      'fatigueScore': fatigueScore,
      'isAccidentDetected': isAccidentDetected,
    };
  }

  factory MonitoringSession.fromMap(Map<String, dynamic> map) {
    final durationMinutes = _parseInt(map['durationMinutes']);
    final endTime = _parseDateTime(map['endTime']);
    final isAccidentDetected = map['isAccidentDetected'] == true;
    final rawStatus = map['status']?.toString();

    final status = SessionStatus.values.firstWhere(
      (e) => e.toString().split('.').last == rawStatus,
      orElse: () {
        if (isAccidentDetected) {
          return SessionStatus.emergency;
        }
        if (endTime != null || durationMinutes > 0) {
          return SessionStatus.completed;
        }
        return SessionStatus.active;
      },
    );

    return MonitoringSession(
      sessionId: map['sessionId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      startTime: _parseDateTime(map['startTime']) ?? DateTime.now(),
      endTime: endTime,
      durationMinutes: durationMinutes,
      totalAlerts: _parseInt(map['totalAlerts']),
      status: status,
      fatigueScore: (map['fatigueScore'] as num?)?.toDouble() ?? 0.0,
      isAccidentDetected: isAccidentDetected,
    );
  }
}

class AlertEvent {
  final String alertId;
  final String sessionId;
  final String userId;
  final AlertType type;
  final DateTime alertTime;
  final Severity severity;
  final String? details;

  AlertEvent({
    required this.alertId,
    required this.sessionId,
    required this.userId,
    required this.type,
    required this.alertTime,
    required this.severity,
    this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'alertId': alertId,
      'sessionId': sessionId,
      'userId': userId,
      'type': type.toString().split('.').last,
      'alertTime': alertTime.toIso8601String(),
      'severity': severity.toString().split('.').last,
      'details': details,
    };
  }

  factory AlertEvent.fromMap(Map<String, dynamic> map) {
    return AlertEvent(
      alertId: map['alertId']?.toString() ?? '',
      sessionId: map['sessionId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      type: AlertType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => AlertType.distraction,
      ),
      alertTime: _parseDateTime(map['alertTime']) ?? DateTime.now(),
      severity: Severity.values.firstWhere(
        (e) => e.toString().split('.').last == map['severity'],
        orElse: () => Severity.medium,
      ),
      details: map['details']?.toString(),
    );
  }
}

class IncidentReport {
  final String incidentId;
  final String sessionId;
  final String userId;
  final DateTime incidentTime;
  final Severity severity;
  final String description;
  final double? latitude;
  final double? longitude;

  IncidentReport({
    required this.incidentId,
    required this.sessionId,
    required this.userId,
    required this.incidentTime,
    required this.severity,
    required this.description,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'incidentId': incidentId,
      'sessionId': sessionId,
      'userId': userId,
      'incidentTime': incidentTime.toIso8601String(),
      'severity': severity.toString().split('.').last,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory IncidentReport.fromMap(Map<String, dynamic> map) {
    return IncidentReport(
      incidentId: map['incidentId']?.toString() ?? '',
      sessionId: map['sessionId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      incidentTime: _parseDateTime(map['incidentTime']) ?? DateTime.now(),
      severity: Severity.values.firstWhere(
        (e) => e.toString().split('.').last == map['severity'],
        orElse: () => Severity.medium,
      ),
      description: map['description']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  final text = value.toString();
  if (text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text);
}

int _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
