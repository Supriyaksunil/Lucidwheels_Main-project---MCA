import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyAlertRecord {
  const EmergencyAlertRecord({
    required this.alertId,
    required this.driverId,
    required this.driverName,
    required this.message,
    required this.reason,
    required this.mapUrl,
    required this.latitude,
    required this.longitude,
    required this.triggeredAt,
    this.recipientUserId,
    this.recipientPhone,
  });

  final String alertId;
  final String driverId;
  final String driverName;
  final String message;
  final String reason;
  final String mapUrl;
  final double latitude;
  final double longitude;
  final DateTime triggeredAt;
  final String? recipientUserId;
  final String? recipientPhone;

  Map<String, dynamic> toMap() {
    return {
      'alertId': alertId,
      'driverId': driverId,
      'driverName': driverName,
      'message': message,
      'reason': reason,
      'mapUrl': mapUrl,
      'latitude': latitude,
      'longitude': longitude,
      'triggeredAt': triggeredAt.toIso8601String(),
      'recipientUserId': recipientUserId,
      'recipientPhone': recipientPhone,
    };
  }

  factory EmergencyAlertRecord.fromMap(Map<String, dynamic> map) {
    return EmergencyAlertRecord(
      alertId: map['alertId']?.toString() ?? '',
      driverId: map['driverId']?.toString() ?? '',
      driverName: map['driverName']?.toString() ?? 'Driver',
      message: map['message']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
      mapUrl: map['mapUrl']?.toString() ?? '',
      latitude: _parseDouble(map['latitude']),
      longitude: _parseDouble(map['longitude']),
      triggeredAt: _parseDateTime(map['triggeredAt']),
      recipientUserId: _parseOptionalString(map['recipientUserId']),
      recipientPhone: _parseOptionalString(map['recipientPhone']),
    );
  }

  EmergencyAlertRecord copyWith({
    String? alertId,
    String? driverId,
    String? driverName,
    String? message,
    String? reason,
    String? mapUrl,
    double? latitude,
    double? longitude,
    DateTime? triggeredAt,
    String? recipientUserId,
    String? recipientPhone,
  }) {
    return EmergencyAlertRecord(
      alertId: alertId ?? this.alertId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      message: message ?? this.message,
      reason: reason ?? this.reason,
      mapUrl: mapUrl ?? this.mapUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      recipientPhone: recipientPhone ?? this.recipientPhone,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static String? _parseOptionalString(dynamic value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw;
  }
}
