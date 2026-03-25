import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_model.dart';

class FleetModel {
  final String fleetId;
  final String companyName;
  final String managerId;
  final DateTime createdAt;
  final List<FleetDriver> drivers;

  const FleetModel({
    required this.fleetId,
    required this.companyName,
    required this.managerId,
    required this.createdAt,
    this.drivers = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'fleetId': fleetId,
      'companyName': companyName,
      'managerId': managerId,
      'createdAt': createdAt.toIso8601String(),
      'drivers': drivers.map((driver) => driver.toMap()).toList(),
    };
  }

  factory FleetModel.fromMap(Map<String, dynamic> map) {
    final rawDrivers = map['drivers'] as List?;
    final legacyDriverIds = (map['driverIds'] as List?)
            ?.map((driverId) => driverId.toString())
            .where((driverId) => driverId.isNotEmpty)
            .toList() ??
        <String>[];

    return FleetModel(
      fleetId: map['fleetId']?.toString() ?? '',
      companyName:
          map['companyName']?.toString() ?? map['name']?.toString() ?? '',
      managerId:
          map['managerId']?.toString() ?? map['adminId']?.toString() ?? '',
      createdAt: _parseDateTime(map['createdAt']),
      drivers: rawDrivers != null
          ? rawDrivers
              .map(
                (driver) => FleetDriver.fromMap(
                  Map<String, dynamic>.from(driver as Map),
                ),
              )
              .toList()
          : legacyDriverIds
              .map(
                (driverId) => FleetDriver(
                  driverId: '',
                  name: '',
                  driverUniqueId: driverId,
                  contactEmail: '',
                ),
              )
              .toList(),
    );
  }

  FleetModel copyWith({
    String? fleetId,
    String? companyName,
    String? managerId,
    DateTime? createdAt,
    List<FleetDriver>? drivers,
  }) {
    return FleetModel(
      fleetId: fleetId ?? this.fleetId,
      companyName: companyName ?? this.companyName,
      managerId: managerId ?? this.managerId,
      createdAt: createdAt ?? this.createdAt,
      drivers: drivers ?? this.drivers,
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
}

class FleetDriver {
  final String driverId;
  final String name;
  final String driverUniqueId;
  final String contactEmail;

  bool get hasLinkedAccount => driverId.trim().isNotEmpty;

  const FleetDriver({
    required this.driverId,
    required this.name,
    required this.driverUniqueId,
    required this.contactEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'name': name,
      'driverUniqueId': driverUniqueId,
      'contactEmail': contactEmail,
    };
  }

  factory FleetDriver.fromMap(Map<String, dynamic> map) {
    return FleetDriver(
      driverId: map['driverId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      driverUniqueId: map['driverUniqueId']?.toString() ?? '',
      contactEmail:
          map['contactEmail']?.toString() ?? map['email']?.toString() ?? '',
    );
  }

  FleetDriver copyWith({
    String? driverId,
    String? name,
    String? driverUniqueId,
    String? contactEmail,
  }) {
    return FleetDriver(
      driverId: driverId ?? this.driverId,
      name: name ?? this.name,
      driverUniqueId: driverUniqueId ?? this.driverUniqueId,
      contactEmail: contactEmail ?? this.contactEmail,
    );
  }
}

class FleetDriverMember {
  final UserModel user;
  final FleetDriver fleetDriver;

  const FleetDriverMember({
    required this.user,
    required this.fleetDriver,
  });
}

class FleetInvitation {
  final String fleetId;
  final String fleetName;
  final String managerId;
  final String managerName;
  final String managerPhone;
  final String driverName;
  final String driverUniqueId;
  final String contactEmail;
  final bool isJoined;

  const FleetInvitation({
    required this.fleetId,
    required this.fleetName,
    required this.managerId,
    required this.managerName,
    required this.managerPhone,
    required this.driverName,
    required this.driverUniqueId,
    required this.contactEmail,
    required this.isJoined,
  });
}
