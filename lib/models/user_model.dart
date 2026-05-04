import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { personal, commercial, fleetManager, emergencyContact }

extension UserRoleX on UserRole {
  String get storageValue {
    switch (this) {
      case UserRole.fleetManager:
        return 'fleetManager';
      case UserRole.emergencyContact:
        return 'emergencyContact';
      case UserRole.personal:
      case UserRole.commercial:
        return name;
    }
  }
}

class UserModel {
  final String uid;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String phone;
  final UserRole role;
  final DateTime createdAt;
  final String? driverUniqueId;
  final List<String> linkedFleetIds;
  final String? managedFleetId;
  final String? profileImagePath;
  final List<EmergencyContact> emergencyContacts;

  String get fullName => middleName != null && middleName!.isNotEmpty
      ? '$firstName $middleName $lastName'
      : '$firstName $lastName';

  String get name => fullName;

  const UserModel({
    required this.uid,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.createdAt,
    this.driverUniqueId,
    this.linkedFleetIds = const [],
    this.managedFleetId,
    this.profileImagePath,
    this.emergencyContacts = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role.storageValue,
      'createdAt': createdAt.toIso8601String(),
      'driverUniqueId': driverUniqueId,
      'linkedFleetIds': linkedFleetIds,
      'managedFleetId': managedFleetId,
      'profileImagePath': profileImagePath,
      'emergencyContacts': emergencyContacts.map((e) => e.toMap()).toList(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final role = _parseRole(map['role']?.toString());
    final legacyFleetId = map['fleetId']?.toString();
    final rawLinkedFleetIds = (map['linkedFleetIds'] as List?)
            ?.map((fleetId) => fleetId.toString())
            .where((fleetId) => fleetId.isNotEmpty)
            .toList() ??
        <String>[];

    final linkedFleetIds = rawLinkedFleetIds.isNotEmpty
        ? rawLinkedFleetIds.toSet().toList()
        : role == UserRole.commercial &&
                legacyFleetId != null &&
                legacyFleetId.isNotEmpty
            ? [legacyFleetId]
            : <String>[];

    final managedFleetId = map['managedFleetId']?.toString().isNotEmpty == true
        ? map['managedFleetId'].toString()
        : role == UserRole.fleetManager &&
                legacyFleetId != null &&
                legacyFleetId.isNotEmpty
            ? legacyFleetId
            : null;

    return UserModel(
      uid: map['uid']?.toString() ?? '',
      firstName: map['firstName']?.toString() ?? map['name']?.toString() ?? '',
      middleName: map['middleName']?.toString(),
      lastName: map['lastName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      role: role,
      createdAt: _parseDateTime(map['createdAt']),
      driverUniqueId: _parseDriverUniqueId(map['driverUniqueId']),
      linkedFleetIds: linkedFleetIds,
      managedFleetId: managedFleetId,
      profileImagePath: map['profileImagePath']?.toString(),
      emergencyContacts: (map['emergencyContacts'] as List?)
              ?.map((entry) => EmergencyContact.fromMap(
                    Map<String, dynamic>.from(entry as Map),
                  ))
              .toList() ??
          const [],
    );
  }

  UserModel copyWith({
    String? uid,
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
    String? phone,
    UserRole? role,
    DateTime? createdAt,
    String? driverUniqueId,
    List<String>? linkedFleetIds,
    String? managedFleetId,
    String? profileImagePath,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      driverUniqueId: driverUniqueId ?? this.driverUniqueId,
      linkedFleetIds: linkedFleetIds ?? this.linkedFleetIds,
      managedFleetId: managedFleetId ?? this.managedFleetId,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }

  static UserRole _parseRole(String? rawRole) {
    switch (rawRole) {
      case 'commercial':
        return UserRole.commercial;
      case 'admin':
      case 'fleetManager':
        return UserRole.fleetManager;
      case 'emergencyContact':
        return UserRole.emergencyContact;
      case 'personal':
      default:
        return UserRole.personal;
    }
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

  static String? _parseDriverUniqueId(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw;
  }
}

class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String relationship;
  final String? userId;
  final String? fcmToken;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.relationship,
    this.userId,
    this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'relationship': relationship,
      'userId': userId,
      'fcmToken': fcmToken,
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: _parseOptionalString(map['email']),
      relationship: map['relationship']?.toString() ?? '',
      userId: _parseOptionalString(map['userId']),
      fcmToken: _parseOptionalString(map['fcmToken']),
    );
  }

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? relationship,
    String? userId,
    String? fcmToken,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
      userId: userId ?? this.userId,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  static String? _parseOptionalString(dynamic value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw;
  }
}
