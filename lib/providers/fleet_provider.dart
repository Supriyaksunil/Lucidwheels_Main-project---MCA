import 'dart:async';

import 'package:flutter/material.dart';

import '../models/monitoring_session_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../utils/driver_performance_utils.dart';

class FleetProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  UserModel? _boundUser;
  String _boundFingerprint = '';
  StreamSubscription<FleetModel?>? _fleetSubscription;
  StreamSubscription<List<UserModel>>? _driversSubscription;
  StreamSubscription<List<MonitoringSession>>? _sessionsSubscription;
  StreamSubscription<List<IncidentReport>>? _incidentsSubscription;
  StreamSubscription<List<FleetInvitation>>? _commercialInvitesSubscription;

  FleetModel? _currentFleet;
  List<UserModel> _drivers = [];
  List<MonitoringSession> _fleetSessions = [];
  List<IncidentReport> _fleetIncidents = [];
  List<FleetInvitation> _commercialInvitations = [];
  bool _isLoading = false;
  String? _error;

  FleetModel? get currentFleet => _currentFleet;
  List<UserModel> get drivers => _drivers;
  List<MonitoringSession> get fleetSessions => _fleetSessions;
  List<IncidentReport> get fleetIncidents => _fleetIncidents;
  List<FleetInvitation> get commercialInvitations => _commercialInvitations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<FleetDriverMember> get joinedDriverMembers {
    final fleet = _currentFleet;
    if (fleet == null || _drivers.isEmpty) {
      return const [];
    }

    final members = <FleetDriverMember>[];
    for (final fleetDriver in fleet.drivers) {
      UserModel? linkedUser;
      for (final user in _drivers) {
        final sameDriverId = fleetDriver.driverId.trim().isNotEmpty &&
            user.uid == fleetDriver.driverId;
        final sameEmail = fleetDriver.contactEmail.trim().isNotEmpty &&
            user.email.trim().toLowerCase() ==
                fleetDriver.contactEmail.trim().toLowerCase() &&
            user.linkedFleetIds.contains(fleet.fleetId);
        if (sameDriverId || sameEmail) {
          linkedUser = user;
          break;
        }
      }

      if (linkedUser != null) {
        members
            .add(FleetDriverMember(user: linkedUser, fleetDriver: fleetDriver));
      }
    }

    members.sort((a, b) {
      final aName =
          a.user.fullName.trim().isEmpty ? a.user.email : a.user.fullName;
      final bName =
          b.user.fullName.trim().isEmpty ? b.user.email : b.user.fullName;
      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });
    return members;
  }

  List<FleetDriver> get pendingDrivers {
    final invitedDrivers = _currentFleet?.drivers ?? const <FleetDriver>[];
    if (invitedDrivers.isEmpty) {
      return const [];
    }

    final joinedCodes = joinedDriverMembers
        .map((member) => member.fleetDriver.driverUniqueId)
        .toSet();

    final pending = invitedDrivers
        .where(
            (fleetDriver) => !joinedCodes.contains(fleetDriver.driverUniqueId))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return pending;
  }

  int get totalInvitedDrivers => _currentFleet?.drivers.length ?? 0;
  int get joinedDriverCount => joinedDriverMembers.length;
  int get pendingDriverCount => pendingDrivers.length;
  int get totalAlerts =>
      _fleetSessions.fold<int>(0, (sum, session) => sum + session.totalAlerts);
  int get activeDriverCount {
    final recentCutoff = DateTime.now().subtract(const Duration(hours: 24));
    return joinedDriverMembers.where((member) {
      return _fleetSessions.any(
        (session) =>
            session.userId == member.user.uid &&
            (session.status == SessionStatus.active ||
                session.startTime.isAfter(recentCutoff)),
      );
    }).length;
  }

  FleetDriverLiveStats liveStatsForDriver(String driverId) {
    final sessions = _fleetSessions
        .where((session) => session.userId == driverId)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    final incidents = _fleetIncidents
        .where((incident) => incident.userId == driverId)
        .toList()
      ..sort((a, b) => b.incidentTime.compareTo(a.incidentTime));

    if (sessions.isEmpty && incidents.isEmpty) {
      return const FleetDriverLiveStats();
    }

    final totalAlerts =
        sessions.fold<int>(0, (sum, session) => sum + session.totalAlerts);
    final totalMinutes = calculateTotalDrivingMinutes(sessions);
    final incidentCount = incidents.length;

    return FleetDriverLiveStats(
      latestSession: sessions.isEmpty ? null : sessions.first,
      sessionCount: sessions.length,
      totalAlerts: totalAlerts,
      totalMinutes: totalMinutes,
      incidentCount: incidentCount,
      performanceScore: calculatePerformanceScore(
        incidentCount: incidentCount,
        totalMinutes: totalMinutes,
      ),
    );
  }

  void bindUser(UserModel? user) {
    final nextFingerprint = _buildFingerprint(user);
    if (_boundFingerprint == nextFingerprint) {
      return;
    }

    _boundUser = user;
    _boundFingerprint = nextFingerprint;
    _error = null;

    _cancelSubscriptions();
    _currentFleet = null;
    _drivers = [];
    _fleetSessions = [];
    _fleetIncidents = [];
    _commercialInvitations = [];
    _isLoading = false;

    if (user == null) {
      notifyListeners();
      return;
    }

    if (user.role == UserRole.fleetManager) {
      _listenToManagedFleet(user.uid);
    } else if (user.role == UserRole.commercial) {
      _listenToCommercialInvitations(user);
    }

    notifyListeners();
  }

  Future<FleetModel> createFleet({required String companyName}) async {
    if (_boundUser == null || _boundUser!.role != UserRole.fleetManager) {
      throw Exception('Only fleet managers can create fleets.');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      return await _firebaseService.createManagedFleet(
        managerId: _boundUser!.uid,
        companyName: companyName,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> addPendingDriver({
    required String driverName,
    required String driverEmail,
  }) async {
    if (_currentFleet == null) {
      throw Exception('Create a fleet before adding drivers.');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      return await _firebaseService.addDriverToFleet(
        fleetId: _currentFleet!.fleetId,
        driverName: driverName,
        driverEmail: driverEmail,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> joinFleetInvitation(FleetInvitation invitation) async {
    if (_boundUser == null || _boundUser!.role != UserRole.commercial) {
      throw Exception('Only commercial drivers can join fleets.');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebaseService.joinFleetInvitation(
        driver: _boundUser!,
        fleetId: invitation.fleetId,
        driverCode: invitation.driverUniqueId,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> joinFleetWithDriverCode(String driverCode) async {
    if (_boundUser == null || _boundUser!.role != UserRole.commercial) {
      throw Exception('Only commercial drivers can join fleets.');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      return await _firebaseService.joinFleetWithDriverCode(
        driver: _boundUser!,
        driverCode: driverCode,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) {
      return;
    }
    _error = null;
    notifyListeners();
  }

  void _listenToManagedFleet(String managerId) {
    _isLoading = true;
    notifyListeners();

    _fleetSubscription =
        _firebaseService.streamManagedFleet(managerId).listen((fleet) {
      _currentFleet = fleet;
      _drivers = [];
      _fleetSessions = [];
      _fleetIncidents = [];

      _driversSubscription?.cancel();
      _sessionsSubscription?.cancel();
      _incidentsSubscription?.cancel();

      if (fleet != null) {
        _listenToJoinedDrivers(fleet.fleetId);
      } else {
        _isLoading = false;
        notifyListeners();
      }
    }, onError: (error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  void _listenToJoinedDrivers(String fleetId) {
    _driversSubscription =
        _firebaseService.streamFleetJoinedDrivers(fleetId).listen((drivers) {
      _drivers = drivers;
      _sessionsSubscription?.cancel();
      _incidentsSubscription?.cancel();

      final driverIds = drivers.map((driver) => driver.uid).toList();
      _sessionsSubscription =
          _firebaseService.getFleetSessions(driverIds).listen(
        (sessions) {
          _fleetSessions = sessions;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _error = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
      _incidentsSubscription =
          _firebaseService.getFleetIncidents(driverIds).listen(
        (incidents) {
          _fleetIncidents = incidents;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _error = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );

      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  void _listenToCommercialInvitations(UserModel user) {
    _isLoading = true;
    notifyListeners();

    _commercialInvitesSubscription = _firebaseService
        .streamCommercialFleetInvitations(user)
        .listen((invitations) {
      _commercialInvitations = invitations;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  String _buildFingerprint(UserModel? user) {
    if (user == null) {
      return 'signed-out';
    }

    return [
      user.uid,
      user.email.trim().toLowerCase(),
      user.role.storageValue,
      user.managedFleetId ?? '',
      ...user.linkedFleetIds,
    ].join('|');
  }

  void _cancelSubscriptions() {
    _fleetSubscription?.cancel();
    _fleetSubscription = null;
    _driversSubscription?.cancel();
    _driversSubscription = null;
    _sessionsSubscription?.cancel();
    _sessionsSubscription = null;
    _incidentsSubscription?.cancel();
    _incidentsSubscription = null;
    _commercialInvitesSubscription?.cancel();
    _commercialInvitesSubscription = null;
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}

class FleetDriverLiveStats {
  const FleetDriverLiveStats({
    this.latestSession,
    this.sessionCount = 0,
    this.totalAlerts = 0,
    this.totalMinutes = 0,
    this.incidentCount = 0,
    this.performanceScore = 100,
  });

  final MonitoringSession? latestSession;
  final int sessionCount;
  final int totalAlerts;
  final int totalMinutes;
  final int incidentCount;
  final int performanceScore;

  bool get hasSessions => latestSession != null;
  bool get isEmergency =>
      latestSession?.status == SessionStatus.emergency ||
      latestSession?.isAccidentDetected == true;
  bool get isActive => latestSession?.status == SessionStatus.active;
  DateTime? get lastSeenAt =>
      latestSession == null ? null : resolveSessionActivityTime(latestSession!);
  String get hoursDrivenLabel => formatHoursDriven(totalMinutes);
}


