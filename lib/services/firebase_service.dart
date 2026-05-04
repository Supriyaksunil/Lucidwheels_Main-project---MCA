import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;

import '../models/emergency_alert_model.dart';
import '../models/fleet_model.dart';
import '../models/monitoring_session_model.dart';
import '../models/user_model.dart';
export '../models/fleet_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();
  static final RegExp _driverIdRegex = RegExp(r'^\d{10}$');

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signInWithEmail(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final result = await _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    if (result.user != null) {
      return getUserData(result.user!.uid);
    }
    return null;
  }

  Future<UserModel?> registerWithEmail(
    String email,
    String password,
    UserModel userData,
  ) async {
    final normalizedEmail = email.trim().toLowerCase();
    final result = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    if (result.user != null) {
      final newUser = userData.copyWith(
        uid: result.user!.uid,
        email: normalizedEmail,
      );
      await createUserDocument(newUser);
      return newUser;
    }
    return null;
  }

  Future<void> createUserDocument(UserModel user) async {
    final synchronizedContacts = await _synchronizeEmergencyContacts(
      user.emergencyContacts,
    );
    final synchronizedUser = user.copyWith(
      emergencyContacts: synchronizedContacts,
    );
    await _firestore.collection('users').doc(user.uid).set({
      ...synchronizedUser.toMap(),
      'normalizedPhone': _normalizePhone(synchronizedUser.phone),
    }, SetOptions(merge: true));
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return _userFromDocument(doc);
  }

  Stream<UserModel?> streamUserDocument(String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(normalizedUid)
        .snapshots()
        .map(_userFromDocument);
  }

  Stream<UserModel?> streamUserByDriverUniqueId(String driverUniqueId) {
    final normalized = driverUniqueId.trim();
    if (normalized.isEmpty) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .where('driverUniqueId', isEqualTo: normalized)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return _userFromDocument(snapshot.docs.first);
    });
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final rawEmail = email.trim();
    if (rawEmail.isEmpty) {
      return null;
    }

    Future<UserModel?> findByEmail(String queryEmail) async {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: queryEmail)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return _userFromDocument(snapshot.docs.first);
    }

    final exactMatch = await findByEmail(rawEmail);
    if (exactMatch != null) {
      return exactMatch;
    }

    final normalizedEmail = rawEmail.toLowerCase();
    if (normalizedEmail == rawEmail) {
      return null;
    }
    return findByEmail(normalizedEmail);
  }

  Future<UserModel?> getUserByPhone(String phone) async {
    final candidates = await _getUsersByMatchingPhone(phone);
    if (candidates.isEmpty) {
      return null;
    }
    return candidates.first;
  }

  Future<UserModel?> getUserByDriverUniqueId(String driverUniqueId) async {
    final normalized = driverUniqueId.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final snapshot = await _firestore
        .collection('users')
        .where('driverUniqueId', isEqualTo: normalized)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }
    return _userFromDocument(snapshot.docs.first);
  }

  Future<void> updateUser(UserModel user) async {
    final synchronizedContacts = await _synchronizeEmergencyContacts(
      user.emergencyContacts,
    );
    final synchronizedUser = user.copyWith(
      emergencyContacts: synchronizedContacts,
    );
    await _firestore.collection('users').doc(user.uid).set({
      ...synchronizedUser.toMap(),
      'normalizedPhone': _normalizePhone(synchronizedUser.phone),
    }, SetOptions(merge: true));
  }

  Future<void> updateUserNotificationToken(
    String uid,
    String? token, {
    String? phone,
  }) async {
    final trimmedToken = token?.trim();
    await _firestore.collection('users').doc(uid).set({
      'normalizedPhone': _normalizePhone(phone ?? ''),
      'fcmToken': trimmedToken != null && trimmedToken.isNotEmpty
          ? trimmedToken
          : FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  Future<List<String>> getNotificationTokensForEmergencyContacts(
    List<EmergencyContact> contacts,
  ) async {
    final tokens = <String>{};

    for (final contact in contacts) {
      final directToken = _cleanNotificationToken(contact.fcmToken);
      if (directToken != null) {
        tokens.add(directToken);
      }

      final linkedUser = await _resolveEmergencyContactUser(contact);
      if (linkedUser == null) {
        continue;
      }

      final resolvedToken = await _getUserNotificationTokenById(linkedUser.uid);
      if (resolvedToken != null) {
        tokens.add(resolvedToken);
      }
    }

    return tokens.toList(growable: false);
  }

  Future<List<String>> getNotificationTokensForFleetManagers(
    List<String> fleetIds,
  ) async {
    if (fleetIds.isEmpty) {
      return const [];
    }

    final tokens = <String>{};
    final seenManagerIds = <String>{};

    for (final fleetId in fleetIds.map((fleetId) => fleetId.trim()).toSet()) {
      if (fleetId.isEmpty) {
        continue;
      }

      final fleet = await getFleet(fleetId);
      final managerId = fleet?.managerId.trim() ?? '';
      if (managerId.isEmpty || !seenManagerIds.add(managerId)) {
        continue;
      }

      final token = await _getUserNotificationTokenById(managerId);
      if (token != null) {
        tokens.add(token);
      }
    }

    return tokens.toList(growable: false);
  }

  Future<UserModel?> findEmergencyContactUser({
    required String name,
    String? phone,
    String? email,
  }) async {
    final candidates = await _getEmergencyContactCandidates(
      phone: phone,
      email: email,
    );
    return FirebaseService.selectEmergencyContactUser(
      contactName: name,
      contactPhone: phone ?? '',
      contactEmail: email,
      candidates: candidates,
    );
  }

  Future<UserModel?> _resolveEmergencyContactUser(
      EmergencyContact contact) async {
    final userId = contact.userId?.trim();
    final candidates = await _getEmergencyContactCandidates(
      phone: contact.phone,
      email: contact.email,
    );
    if (userId != null && userId.isNotEmpty) {
      final linkedUser = await getUserData(userId);
      if (linkedUser != null) {
        final linkedCandidates = [
          linkedUser,
          ...candidates.where((candidate) => candidate.uid != linkedUser.uid),
        ];
        final matchedUser = FirebaseService.selectEmergencyContactUser(
          contactName: contact.name,
          contactPhone: contact.phone,
          contactEmail: contact.email,
          candidates: linkedCandidates,
          preferredUserId: linkedUser.uid,
        );
        if (matchedUser != null) {
          return matchedUser;
        }
      }
      debugPrint(
        'FirebaseService: stored emergency contact userId no longer matches ${contact.name}',
      );
    }

    return FirebaseService.selectEmergencyContactUser(
      contactName: contact.name,
      contactPhone: contact.phone,
      contactEmail: contact.email,
      candidates: candidates,
    );
  }

  Future<List<UserModel>> _getEmergencyContactCandidates({
    String? phone,
    String? email,
  }) async {
    final users = <UserModel>[];
    final seenUserIds = <String>{};

    void addUser(UserModel? user) {
      final userId = user?.uid.trim() ?? '';
      if (user == null || userId.isEmpty || !seenUserIds.add(userId)) {
        return;
      }
      users.add(user);
    }

    final normalizedEmail = _normalizeEmail(email ?? '');
    if (normalizedEmail.isNotEmpty) {
      addUser(await getUserByEmail(normalizedEmail));
    }

    final rawPhone = phone?.trim() ?? '';
    if (rawPhone.isNotEmpty) {
      for (final user in await _getUsersByMatchingPhone(rawPhone)) {
        addUser(user);
      }
    }

    return users;
  }

  Future<List<UserModel>> _getUsersByMatchingPhone(String phone) async {
    final rawPhone = phone.trim();
    if (rawPhone.isEmpty) {
      return const [];
    }

    final users = <UserModel>[];
    final seenUserIds = <String>{};

    void addUsers(QuerySnapshot<Map<String, dynamic>> snapshot) {
      for (final doc in snapshot.docs) {
        final user = _userFromDocument(doc);
        final userId = user?.uid.trim() ?? '';
        if (user == null || userId.isEmpty || !seenUserIds.add(userId)) {
          continue;
        }
        users.add(user);
      }
    }

    for (final normalizedPhone in FirebaseService.phoneLookupKeys(rawPhone)) {
      final normalizedSnapshot = await _firestore
          .collection('users')
          .where('normalizedPhone', isEqualTo: normalizedPhone)
          .get();
      addUsers(normalizedSnapshot);
    }

    final exactPhoneSnapshot = await _firestore
        .collection('users')
        .where('phone', isEqualTo: rawPhone)
        .get();
    addUsers(exactPhoneSnapshot);

    return users;
  }

  Future<void> createEmergencyAlertRecords({
    required String alertId,
    required List<EmergencyContact> contacts,
    required UserModel driver,
    required String reason,
    required double lat,
    required double lng,
  }) async {
    if (contacts.isEmpty) {
      return;
    }

    final mapUrl = 'https://maps.google.com/?q=$lat,$lng';
    final driverName = _buildEmergencyDriverName(driver);
    final seenRecipients = <String>{};
    final batch = _firestore.batch();
    var queuedRecords = 0;

    for (final contact in contacts) {
      final linkedUser = await _resolveEmergencyContactUser(contact);

      final recipientUserId = linkedUser?.uid.trim() ?? '';
      final recipientPhone = _normalizePhone(
        linkedUser?.phone.trim().isNotEmpty == true
            ? linkedUser!.phone
            : contact.phone,
      );
      if (recipientUserId.isEmpty && recipientPhone.isEmpty) {
        continue;
      }

      final dedupeKey = recipientUserId.isNotEmpty
          ? 'uid:$recipientUserId'
          : 'phone:$recipientPhone';
      if (!seenRecipients.add(dedupeKey)) {
        continue;
      }

      final docRef = _firestore.collection('emergencyAlerts').doc();
      final record = EmergencyAlertRecord(
        alertId: alertId,
        driverId: driver.uid,
        driverName: driverName,
        message: 'Emergency detected for $driverName',
        reason: reason,
        mapUrl: mapUrl,
        latitude: lat,
        longitude: lng,
        triggeredAt: DateTime.now(),
        recipientUserId: recipientUserId.isEmpty ? null : recipientUserId,
        recipientPhone: recipientPhone.isEmpty ? null : recipientPhone,
      );
      batch.set(docRef, record.toMap());
      queuedRecords++;
    }

    if (queuedRecords > 0) {
      await batch.commit();
    }
  }

  Future<String?> _getUserNotificationTokenById(String userId) async {
    final snapshot = await _firestore.collection('users').doc(userId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return _cleanNotificationToken(snapshot.data()!['fcmToken']);
  }

  Future<String> generateDriverUniqueId() async {
    while (true) {
      final driverUniqueId = _buildRandomDriverId();
      final alreadyAllocated = await _isDriverCodeAllocated(driverUniqueId);
      if (!alreadyAllocated) {
        return driverUniqueId;
      }
    }
  }

  Future<String> ensureDriverUniqueId(UserModel user) async {
    if (user.driverUniqueId != null &&
        _driverIdRegex.hasMatch(user.driverUniqueId!)) {
      return user.driverUniqueId!;
    }

    final generatedId = await generateDriverUniqueId();
    await _firestore.collection('users').doc(user.uid).set({
      'driverUniqueId': generatedId,
      'role': UserRole.commercial.storageValue,
      'linkedFleetIds': user.linkedFleetIds,
    }, SetOptions(merge: true));
    return generatedId;
  }

  Future<String> createSession(MonitoringSession session) async {
    final docRef = _firestore.collection('sessions').doc();
    final sessionWithId = MonitoringSession(
      sessionId: docRef.id,
      userId: session.userId,
      startTime: session.startTime,
    );
    await docRef.set(sessionWithId.toMap());
    return docRef.id;
  }

  Future<void> updateSession(MonitoringSession session) async {
    await _firestore
        .collection('sessions')
        .doc(session.sessionId)
        .update(session.toMap());
  }

  Future<void> addAlert(AlertEvent alert) async {
    await _firestore.collection('alerts').add(alert.toMap());
    await _firestore.collection('sessions').doc(alert.sessionId).update({
      'totalAlerts': FieldValue.increment(1),
    });
  }

  Future<void> addIncident(IncidentReport incident) async {
    await _firestore.collection('incidents').add(incident.toMap());
  }

  Stream<List<MonitoringSession>> getUserSessions(String userId) {
    return _firestore
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final sessions = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['sessionId'] = data['sessionId'] ?? doc.id;
        return MonitoringSession.fromMap(data);
      }).toList();
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      return sessions;
    });
  }

  Stream<int> getUserAlertCountToday(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('alerts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      var count = 0;
      for (final doc in snapshot.docs) {
        final rawTime = doc.data()['alertTime'];
        final alertTime = _parseDateTime(rawTime);
        if (alertTime != null &&
            !alertTime.isBefore(startOfDay) &&
            alertTime.isBefore(endOfDay)) {
          count++;
        }
      }
      return count;
    });
  }

  Stream<int> getUserIncidentCount(String userId) {
    return _firestore
        .collection('incidents')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<IncidentReport>> getUserIncidents(
    String userId, {
    int limit = 100,
  }) {
    return _firestore
        .collection('incidents')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final incidents = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['incidentId'] = data['incidentId'] ?? doc.id;
        return IncidentReport.fromMap(data);
      }).toList();

      incidents.sort((a, b) => b.incidentTime.compareTo(a.incidentTime));
      if (incidents.length > limit) {
        return incidents.sublist(0, limit);
      }
      return incidents;
    });
  }

  Stream<List<AlertEvent>> getUserAlerts(String userId, {int limit = 20}) {
    return _firestore
        .collection('alerts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final alerts = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['alertId'] = data['alertId'] ?? doc.id;
        return AlertEvent.fromMap(data);
      }).toList();

      alerts.sort((a, b) => b.alertTime.compareTo(a.alertTime));
      if (alerts.length > limit) {
        return alerts.sublist(0, limit);
      }
      return alerts;
    });
  }

  Stream<List<EmergencyAlertRecord>> streamEmergencyAlertsForUser(
    UserModel user, {
    int limit = 50,
  }) {
    final userId = user.uid.trim();
    if (userId.isEmpty) {
      return Stream.value(const []);
    }

    return _firestore
        .collection('emergencyAlerts')
        .where('recipientUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final alerts = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['alertId'] = data['alertId'] ?? doc.id;
        return EmergencyAlertRecord.fromMap(data);
      }).toList();

      alerts.sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
      if (alerts.length > limit) {
        return alerts.sublist(0, limit);
      }
      return alerts;
    });
  }

  Future<FleetModel> createManagedFleet({
    required String managerId,
    required String companyName,
  }) async {
    final trimmedCompanyName = companyName.trim();
    if (trimmedCompanyName.isEmpty) {
      throw Exception('Company name is required.');
    }

    final existingFleetSnapshot = await _firestore
        .collection('fleets')
        .where('managerId', isEqualTo: managerId)
        .limit(1)
        .get();
    if (existingFleetSnapshot.docs.isNotEmpty) {
      throw Exception('You already manage a fleet.');
    }

    final docRef = _firestore.collection('fleets').doc();
    final fleet = FleetModel(
      fleetId: docRef.id,
      companyName: trimmedCompanyName,
      managerId: managerId,
      createdAt: DateTime.now(),
      drivers: const [],
    );

    final batch = _firestore.batch();
    batch.set(docRef, fleet.toMap());
    batch.set(
      _firestore.collection('users').doc(managerId),
      {
        'managedFleetId': docRef.id,
        'role': UserRole.fleetManager.storageValue,
      },
      SetOptions(merge: true),
    );
    await batch.commit();

    return fleet;
  }

  Stream<FleetModel?> streamManagedFleet(String managerId) {
    return _firestore
        .collection('fleets')
        .where('managerId', isEqualTo: managerId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return FleetModel.fromMap(snapshot.docs.first.data());
    });
  }

  Future<String> addDriverToFleet({
    required String fleetId,
    required String driverName,
    required String driverEmail,
    String? preferredDriverUniqueId,
  }) async {
    final normalizedName = driverName.trim();
    if (normalizedName.isEmpty) {
      throw Exception('Driver name is required.');
    }

    final normalizedEmail = _normalizeEmail(driverEmail);
    if (normalizedEmail.isEmpty) {
      throw Exception('Driver email is required.');
    }

    final rawPreferredId = preferredDriverUniqueId?.trim() ?? '';
    if (rawPreferredId.isNotEmpty && !_driverIdRegex.hasMatch(rawPreferredId)) {
      throw Exception('Driver ID must be exactly 10 digits.');
    }

    final driverUniqueId = rawPreferredId.isNotEmpty
        ? rawPreferredId
        : await generateDriverUniqueId();
    var resolvedDriverUniqueId = driverUniqueId;
    final fleetRef = _firestore.collection('fleets').doc(fleetId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(fleetRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('Fleet not found.');
      }

      final fleet = FleetModel.fromMap(snapshot.data()!);
      final existingPendingIndex = fleet.drivers.indexWhere(
        (fleetDriver) =>
            fleetDriver.driverId.trim().isEmpty &&
            _normalizeEmail(fleetDriver.contactEmail) == normalizedEmail,
      );
      if (existingPendingIndex >= 0) {
        final updatedDrivers = [...fleet.drivers];
        final existingDriver = updatedDrivers[existingPendingIndex];
        resolvedDriverUniqueId = existingDriver.driverUniqueId;
        updatedDrivers[existingPendingIndex] = existingDriver.copyWith(
          name: normalizedName,
          contactEmail: normalizedEmail,
        );
        updatedDrivers.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        transaction.update(fleetRef, {
          'drivers':
              updatedDrivers.map((fleetDriver) => fleetDriver.toMap()).toList(),
        });
        return;
      }

      final alreadyJoined = fleet.drivers.any(
        (fleetDriver) =>
            fleetDriver.driverId.trim().isNotEmpty &&
            _normalizeEmail(fleetDriver.contactEmail) == normalizedEmail,
      );
      if (alreadyJoined) {
        throw Exception('Driver already joined this fleet.');
      }

      final codeAlreadyExists = fleet.drivers.any(
        (fleetDriver) => fleetDriver.driverUniqueId == driverUniqueId,
      );
      if (codeAlreadyExists) {
        throw Exception('Driver ID already exists in this fleet.');
      }

      final updatedDrivers = [
        ...fleet.drivers,
        FleetDriver(
          driverId: '',
          name: normalizedName,
          driverUniqueId: driverUniqueId,
          contactEmail: normalizedEmail,
        ),
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      transaction.update(fleetRef, {
        'drivers':
            updatedDrivers.map((fleetDriver) => fleetDriver.toMap()).toList(),
      });
    });

    return resolvedDriverUniqueId;
  }

  Future<void> joinFleetInvitation({
    required UserModel driver,
    required String fleetId,
    required String driverCode,
  }) async {
    final normalizedCode = driverCode.trim();
    if (!_driverIdRegex.hasMatch(normalizedCode)) {
      throw Exception('Driver ID must be exactly 10 digits.');
    }
    if (driver.role != UserRole.commercial) {
      throw Exception('Only commercial drivers can join fleets.');
    }

    final fleetRef = _firestore.collection('fleets').doc(fleetId);
    final fleetSnapshot = await fleetRef.get();
    if (!fleetSnapshot.exists || fleetSnapshot.data() == null) {
      throw Exception('Fleet not found.');
    }

    final fleet = FleetModel.fromMap(fleetSnapshot.data()!);
    FleetDriver? matchedDriver;
    var claimedByAnotherAccount = false;

    for (final fleetDriver in fleet.drivers) {
      if (fleetDriver.driverUniqueId != normalizedCode) {
        continue;
      }

      if (!FirebaseService.canDriverClaimFleetInvitation(
        fleetDriver: fleetDriver,
        driver: driver,
        driverCode: normalizedCode,
      )) {
        claimedByAnotherAccount = true;
        continue;
      }

      matchedDriver = fleetDriver;
      break;
    }

    if (matchedDriver == null) {
      if (claimedByAnotherAccount) {
        throw Exception(
            'This driver ID has already been used by another account.');
      }
      throw Exception('No fleet invitation found for this driver.');
    }

    if (driver.linkedFleetIds.contains(fleetId)) {
      throw Exception('You have already joined this fleet.');
    }

    final manager = await getUserData(fleet.managerId);
    final updatedEmergencyContacts = await _synchronizeEmergencyContacts(
      _mergeFleetManagerEmergencyContact(
        driver.emergencyContacts,
        manager,
      ),
    );
    final resolvedDriverName = driver.fullName.trim().isEmpty
        ? driver.email.trim()
        : driver.fullName.trim();
    final updatedDrivers = fleet.drivers.map((fleetDriver) {
      if (fleetDriver.driverUniqueId != normalizedCode) {
        return fleetDriver;
      }

      final linkedDriverId = fleetDriver.driverId.trim();
      if (linkedDriverId.isNotEmpty && linkedDriverId != driver.uid) {
        return fleetDriver;
      }

      return fleetDriver.copyWith(
        driverId: driver.uid,
        name: resolvedDriverName,
        contactEmail: _normalizeEmail(driver.email),
      );
    }).toList();

    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(driver.uid);
    batch.set(
      userRef,
      {
        'role': UserRole.commercial.storageValue,
        'driverUniqueId': normalizedCode,
        'linkedFleetIds': FieldValue.arrayUnion([fleetId]),
        'emergencyContacts':
            updatedEmergencyContacts.map((contact) => contact.toMap()).toList(),
      },
      SetOptions(merge: true),
    );
    batch.update(fleetRef, {
      'drivers':
          updatedDrivers.map((fleetDriver) => fleetDriver.toMap()).toList(),
    });

    await batch.commit();
  }

  Future<int> joinFleetWithDriverCode({
    required UserModel driver,
    required String driverCode,
  }) async {
    final normalizedCode = driverCode.trim();
    if (!_driverIdRegex.hasMatch(normalizedCode)) {
      throw Exception('Driver ID must be exactly 10 digits.');
    }

    final fleetsSnapshot = await _firestore.collection('fleets').get();
    final matchingFleets = <FleetModel>[];
    var claimedByAnotherAccount = false;

    for (final doc in fleetsSnapshot.docs) {
      final fleet = FleetModel.fromMap(doc.data());
      for (final fleetDriver in fleet.drivers) {
        if (fleetDriver.driverUniqueId != normalizedCode) {
          continue;
        }

        if (!FirebaseService.canDriverClaimFleetInvitation(
          fleetDriver: fleetDriver,
          driver: driver,
          driverCode: normalizedCode,
        )) {
          claimedByAnotherAccount = true;
          continue;
        }

        if (!driver.linkedFleetIds.contains(fleet.fleetId)) {
          matchingFleets.add(fleet);
        }
        break;
      }
    }

    if (matchingFleets.isEmpty) {
      if (claimedByAnotherAccount) {
        throw Exception(
            'This driver ID has already been used by another account.');
      }
      throw Exception('No fleet invitation found for that driver ID.');
    }

    for (final fleet in matchingFleets) {
      await joinFleetInvitation(
        driver: driver,
        fleetId: fleet.fleetId,
        driverCode: normalizedCode,
      );
    }

    return matchingFleets.length;
  }

  Stream<List<UserModel>> streamFleetJoinedDrivers(String fleetId) {
    return _firestore
        .collection('users')
        .where('linkedFleetIds', arrayContains: fleetId)
        .snapshots()
        .map((snapshot) {
      final drivers = snapshot.docs
          .map((doc) => _userFromDocument(doc))
          .whereType<UserModel>()
          .where((user) => user.role == UserRole.commercial)
          .toList()
        ..sort((a, b) => a.fullName.compareTo(b.fullName));
      return drivers;
    });
  }

  Stream<List<UserModel>> getFleetDrivers(String fleetId) {
    return streamFleetJoinedDrivers(fleetId);
  }

  Stream<List<FleetInvitation>> streamCommercialFleetInvitations(
    UserModel driver,
  ) {
    final normalizedEmail = _normalizeEmail(driver.email);

    return _firestore
        .collection('fleets')
        .snapshots()
        .asyncMap((snapshot) async {
      final fleets =
          snapshot.docs.map((doc) => FleetModel.fromMap(doc.data())).toList();
      final matches = <MapEntry<FleetModel, FleetDriver>>[];
      final managerIds = <String>{};

      for (final fleet in fleets) {
        for (final fleetDriver in fleet.drivers) {
          final emailMatches = normalizedEmail.isNotEmpty &&
              _normalizeEmail(fleetDriver.contactEmail) == normalizedEmail;
          final accountMatches = fleetDriver.driverId.trim().isNotEmpty &&
              fleetDriver.driverId == driver.uid;
          final linkedMatches = driver.linkedFleetIds.contains(fleet.fleetId) &&
              (fleetDriver.driverId == driver.uid || emailMatches);
          if (emailMatches || accountMatches || linkedMatches) {
            matches.add(MapEntry(fleet, fleetDriver));
            managerIds.add(fleet.managerId);
            break;
          }
        }
      }

      if (matches.isEmpty) {
        return const <FleetInvitation>[];
      }

      final managers = <String, UserModel?>{};
      for (final managerId in managerIds) {
        managers[managerId] = await getUserData(managerId);
      }

      final invitations = matches.map((entry) {
        final fleet = entry.key;
        final fleetDriver = entry.value;
        final manager = managers[fleet.managerId];
        final managerName = manager == null
            ? 'Fleet Manager'
            : manager.fullName.trim().isEmpty
                ? manager.email.trim()
                : manager.fullName.trim();
        final isJoined = driver.linkedFleetIds.contains(fleet.fleetId) ||
            fleetDriver.driverId.trim() == driver.uid;

        return FleetInvitation(
          fleetId: fleet.fleetId,
          fleetName: fleet.companyName,
          managerId: fleet.managerId,
          managerName: managerName,
          managerPhone: manager?.phone.trim() ?? '',
          driverName: fleetDriver.name,
          driverUniqueId: fleetDriver.driverUniqueId,
          contactEmail: fleetDriver.contactEmail,
          isJoined: isJoined,
        );
      }).toList()
        ..sort((a, b) {
          if (a.isJoined != b.isJoined) {
            return a.isJoined ? 1 : -1;
          }
          return a.fleetName.toLowerCase().compareTo(b.fleetName.toLowerCase());
        });

      return invitations;
    });
  }

  Stream<List<MonitoringSession>> getFleetSessions(List<String> driverIds) {
    if (driverIds.isEmpty) {
      return Stream.value(const []);
    }

    final uniqueDriverIds = driverIds.toSet().toList();
    if (uniqueDriverIds.length <= 10) {
      return _firestore
          .collection('sessions')
          .where('userId', whereIn: uniqueDriverIds)
          .snapshots()
          .map((snapshot) {
        final sessions = snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['sessionId'] = data['sessionId'] ?? doc.id;
          return MonitoringSession.fromMap(data);
        }).toList();
        sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
        return sessions;
      });
    }

    return _firestore.collection('sessions').snapshots().map((snapshot) {
      final driverIdSet = uniqueDriverIds.toSet();
      final sessions = snapshot.docs
          .map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['sessionId'] = data['sessionId'] ?? doc.id;
            return MonitoringSession.fromMap(data);
          })
          .where((session) => driverIdSet.contains(session.userId))
          .toList();
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      return sessions;
    });
  }

  Stream<List<IncidentReport>> getFleetIncidents(List<String> driverIds) {
    if (driverIds.isEmpty) {
      return Stream.value(const []);
    }

    final uniqueDriverIds = driverIds.toSet().toList();
    if (uniqueDriverIds.length <= 10) {
      return _firestore
          .collection('incidents')
          .where('userId', whereIn: uniqueDriverIds)
          .snapshots()
          .map((snapshot) {
        final incidents = snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['incidentId'] = data['incidentId'] ?? doc.id;
          return IncidentReport.fromMap(data);
        }).toList();
        incidents.sort((a, b) => b.incidentTime.compareTo(a.incidentTime));
        return incidents;
      });
    }

    return _firestore.collection('incidents').snapshots().map((snapshot) {
      final driverIdSet = uniqueDriverIds.toSet();
      final incidents = snapshot.docs
          .map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['incidentId'] = data['incidentId'] ?? doc.id;
            return IncidentReport.fromMap(data);
          })
          .where((incident) => driverIdSet.contains(incident.userId))
          .toList();
      incidents.sort((a, b) => b.incidentTime.compareTo(a.incidentTime));
      return incidents;
    });
  }

  Future<FleetModel?> getFleet(String fleetId) async {
    final doc = await _firestore.collection('fleets').doc(fleetId).get();
    if (doc.exists && doc.data() != null) {
      return FleetModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<bool> _isDriverCodeAllocated(String driverUniqueId) async {
    final existingUser = await getUserByDriverUniqueId(driverUniqueId);
    if (existingUser != null) {
      return true;
    }

    final fleetsSnapshot = await _firestore.collection('fleets').get();
    for (final doc in fleetsSnapshot.docs) {
      final fleet = FleetModel.fromMap(doc.data());
      final existsInFleet = fleet.drivers.any(
        (fleetDriver) => fleetDriver.driverUniqueId == driverUniqueId,
      );
      if (existsInFleet) {
        return true;
      }
    }

    return false;
  }

  UserModel? _userFromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (!doc.exists || data == null) {
      return null;
    }
    return UserModel.fromMap({
      ...data,
      'uid': data['uid']?.toString().isNotEmpty == true ? data['uid'] : doc.id,
    });
  }

  String _buildEmergencyDriverName(UserModel driver) {
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

  @visibleForTesting
  static bool canDriverClaimFleetInvitation({
    required FleetDriver fleetDriver,
    required UserModel driver,
    required String driverCode,
  }) {
    final normalizedCode = driverCode.trim();
    if (normalizedCode.isEmpty ||
        fleetDriver.driverUniqueId != normalizedCode) {
      return false;
    }

    final linkedDriverId = fleetDriver.driverId.trim();
    return linkedDriverId.isEmpty || linkedDriverId == driver.uid;
  }

  @visibleForTesting
  static bool emergencyContactMatchesUser({
    required String contactName,
    required String contactPhone,
    required UserModel user,
  }) {
    final normalizedContactName = normalizeEmergencyContactName(contactName);
    final normalizedContactPhone = normalizePhoneForMatching(contactPhone);
    final normalizedUserPhone = normalizePhoneForMatching(user.phone);
    if (normalizedContactName.isEmpty ||
        normalizedContactPhone.isEmpty ||
        normalizedUserPhone.isEmpty ||
        normalizedContactPhone != normalizedUserPhone) {
      return false;
    }

    final userNames = <String>{
      normalizeEmergencyContactName(user.fullName),
      normalizeEmergencyContactName('${user.firstName} ${user.lastName}'),
    }..removeWhere((value) => value.isEmpty);

    return userNames.contains(normalizedContactName);
  }

  @visibleForTesting
  static UserModel? selectEmergencyContactUser({
    required String contactName,
    required String contactPhone,
    String? contactEmail,
    required List<UserModel> candidates,
    String? preferredUserId,
  }) {
    if (candidates.isEmpty) {
      return null;
    }

    final normalizedContactEmail =
        normalizeEmailForMatching(contactEmail ?? '');
    final normalizedContactPhone = normalizePhoneForMatching(contactPhone);
    final preferredId = preferredUserId?.trim() ?? '';
    final emailMatches = normalizedContactEmail.isEmpty
        ? <UserModel>[]
        : candidates.where((candidate) {
            return normalizeEmailForMatching(candidate.email) ==
                normalizedContactEmail;
          }).toList();
    final phoneMatches = normalizedContactPhone.isEmpty
        ? <UserModel>[]
        : candidates.where((candidate) {
            return normalizePhoneForMatching(candidate.phone) ==
                normalizedContactPhone;
          }).toList();

    if (preferredId.isNotEmpty) {
      for (final candidate in candidates) {
        if (candidate.uid != preferredId) {
          continue;
        }
        final emailMatchesCandidate = normalizedContactEmail.isEmpty ||
            normalizeEmailForMatching(candidate.email) ==
                normalizedContactEmail;
        final phoneMatchesCandidate = normalizedContactPhone.isEmpty ||
            normalizePhoneForMatching(candidate.phone) ==
                normalizedContactPhone;
        if (emailMatchesCandidate || phoneMatchesCandidate) {
          return candidate;
        }
      }
    }

    if (emailMatches.length == 1) {
      return emailMatches.first;
    }

    for (final candidate in phoneMatches) {
      if (FirebaseService.emergencyContactMatchesUser(
        contactName: contactName,
        contactPhone: contactPhone,
        user: candidate,
      )) {
        return candidate;
      }
    }

    final emergencyContactPhoneMatches = phoneMatches
        .where((candidate) => candidate.role == UserRole.emergencyContact)
        .toList(growable: false);
    if (emergencyContactPhoneMatches.length == 1) {
      return emergencyContactPhoneMatches.first;
    }

    return null;
  }

  @visibleForTesting
  static String normalizeEmergencyContactName(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @visibleForTesting
  static String normalizeEmailForMatching(String value) {
    return value.trim().toLowerCase();
  }

  @visibleForTesting
  static String normalizePhoneForMatching(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  @visibleForTesting
  static Set<String> phoneLookupKeys(String value) {
    final digitsOnly = normalizePhoneForMatching(value);
    final legacyFormat = value.replaceAll(RegExp(r'[^0-9+]'), '');
    return {
      if (digitsOnly.isNotEmpty) digitsOnly,
      if (legacyFormat.isNotEmpty) legacyFormat,
    };
  }

  List<EmergencyContact> _mergeFleetManagerEmergencyContact(
    List<EmergencyContact> contacts,
    UserModel? manager,
  ) {
    if (manager == null) {
      return contacts;
    }

    final managerName = manager.fullName.trim().isEmpty
        ? manager.email.trim()
        : manager.fullName.trim();
    final managerPhone = manager.phone.trim();
    final managerEmail = _normalizeEmail(manager.email);
    if (managerName.isEmpty ||
        (managerPhone.isEmpty &&
            managerEmail.isEmpty &&
            manager.uid.trim().isEmpty)) {
      return contacts;
    }

    final contactId = 'fleet-manager-${manager.uid}';
    final alreadyExists = contacts.any(
      (contact) =>
          contact.id == contactId ||
          contact.userId == manager.uid ||
          (_normalizeEmail(contact.email ?? '') == managerEmail &&
              managerEmail.isNotEmpty) ||
          (contact.name == managerName && contact.phone == managerPhone),
    );
    if (alreadyExists) {
      return contacts;
    }

    return [
      ...contacts,
      EmergencyContact(
        id: contactId,
        name: managerName,
        phone: managerPhone,
        email: managerEmail.isEmpty ? null : managerEmail,
        relationship: 'Fleet Manager',
        userId: manager.uid,
      ),
    ];
  }

  String _normalizePhone(String value) {
    return normalizePhoneForMatching(value);
  }

  Future<List<EmergencyContact>> _synchronizeEmergencyContacts(
    List<EmergencyContact> contacts,
  ) async {
    if (contacts.isEmpty) {
      return const [];
    }

    final synchronizedContacts = <EmergencyContact>[];
    for (final contact in contacts) {
      final linkedUser = await _resolveEmergencyContactUser(contact);
      final resolvedToken = linkedUser == null
          ? null
          : await _getUserNotificationTokenById(linkedUser.uid);
      synchronizedContacts.add(
        EmergencyContact(
          id: contact.id,
          name: contact.name,
          phone: contact.phone,
          email: contact.email,
          relationship: contact.relationship,
          userId: linkedUser?.uid,
          fcmToken: resolvedToken ?? _cleanNotificationToken(contact.fcmToken),
        ),
      );
    }
    return synchronizedContacts;
  }

  String _normalizeEmail(String value) {
    return value.trim().toLowerCase();
  }

  String? _cleanNotificationToken(dynamic value) {
    final token = value?.toString().trim();
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  String _buildRandomDriverId() {
    final firstDigit = 1 + _random.nextInt(9);
    final remainingDigits = List.generate(9, (_) => _random.nextInt(10)).join();
    return '$firstDigit$remainingDigits';
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
