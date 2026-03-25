import 'package:flutter_test/flutter_test.dart';
import 'package:lucidwheels/models/monitoring_session_model.dart';
import 'package:lucidwheels/models/user_model.dart';
import 'package:lucidwheels/providers/monitoring_provider.dart';
import 'package:lucidwheels/services/emergency_service.dart';
import 'package:lucidwheels/services/firebase_service.dart';
import 'package:lucidwheels/widgets/safety_alert_screen.dart';

void main() {
  group('Safety confirmation phrases', () {
    test('accepts yes in a case-insensitive way', () {
      expect(matchesSafetyConfirmationPhrase('YES'), isTrue);
      expect(matchesSafetyConfirmationPhrase('yes, I am safe'), isTrue);
    });

    test('accepts safe phrases with small variations', () {
      expect(matchesSafetyConfirmationPhrase('I am safe'), isTrue);
      expect(matchesSafetyConfirmationPhrase("I'm safe"), isTrue);
      expect(matchesSafetyConfirmationPhrase('I\u2019m safe'), isTrue);
      expect(matchesSafetyConfirmationPhrase('im safe'), isTrue);
      expect(matchesSafetyConfirmationPhrase('i m safe'), isTrue);
    });

    test('rejects unrelated phrases', () {
      expect(matchesSafetyConfirmationPhrase('no'), isFalse);
      expect(matchesSafetyConfirmationPhrase('help me'), isFalse);
    });
  });

  group('MonitoringProvider alert lock', () {
    test('detects whether an alert flow is already active', () {
      expect(
        MonitoringProvider.hasActiveAlertFlow(
          isSafetyConfirmationInProgress: false,
          showAlertOverlay: false,
          activeAlertType: null,
        ),
        isFalse,
      );

      expect(
        MonitoringProvider.hasActiveAlertFlow(
          isSafetyConfirmationInProgress: true,
          showAlertOverlay: false,
          activeAlertType: null,
        ),
        isTrue,
      );

      expect(
        MonitoringProvider.hasActiveAlertFlow(
          isSafetyConfirmationInProgress: false,
          showAlertOverlay: true,
          activeAlertType: AlertType.drowsiness,
        ),
        isTrue,
      );
    });

    test('blocks competing alerts unless takeover is explicitly allowed', () {
      expect(
        MonitoringProvider.shouldBlockIncomingAlert(
          isMonitoring: true,
          isSafetyConfirmationInProgress: false,
          showAlertOverlay: true,
          activeAlertType: AlertType.drowsiness,
        ),
        isTrue,
      );

      expect(
        MonitoringProvider.shouldBlockIncomingAlert(
          isMonitoring: true,
          isSafetyConfirmationInProgress: false,
          showAlertOverlay: true,
          activeAlertType: AlertType.drowsiness,
          allowTakeover: true,
        ),
        isFalse,
      );

      expect(
        MonitoringProvider.shouldBlockIncomingAlert(
          isMonitoring: false,
          isSafetyConfirmationInProgress: false,
          showAlertOverlay: false,
          activeAlertType: null,
        ),
        isTrue,
      );
    });
  });

  group('Emergency contact matching', () {
    final emergencyContactUser = UserModel(
      uid: 'contact-1',
      firstName: 'John',
      middleName: 'Quincy',
      lastName: 'Public',
      email: 'john@example.com',
      phone: '+1 (555) 123-4567',
      role: UserRole.emergencyContact,
      createdAt: DateTime(2025, 1, 1),
    );

    test('matches the same contact when name and phone align', () {
      expect(
        FirebaseService.emergencyContactMatchesUser(
          contactName: 'John Quincy Public',
          contactPhone: '15551234567',
          user: emergencyContactUser,
        ),
        isTrue,
      );
    });

    test('matches even when the stored contact omits the middle name', () {
      expect(
        FirebaseService.emergencyContactMatchesUser(
          contactName: 'John Public',
          contactPhone: '+1 555 123 4567',
          user: emergencyContactUser,
        ),
        isTrue,
      );
    });

    test('rejects a phone-only match when the contact name differs', () {
      expect(
        FirebaseService.emergencyContactMatchesUser(
          contactName: 'Jane Public',
          contactPhone: '+1 555 123 4567',
          user: emergencyContactUser,
        ),
        isFalse,
      );
    });

    test('rejects a name-only match when the phone differs', () {
      expect(
        FirebaseService.emergencyContactMatchesUser(
          contactName: 'John Public',
          contactPhone: '+1 555 000 0000',
          user: emergencyContactUser,
        ),
        isFalse,
      );
    });
    test('falls back to a unique emergency contact account on phone match', () {
      final matchedUser = FirebaseService.selectEmergencyContactUser(
        contactName: 'Dad',
        contactPhone: '+1 555 123 4567',
        candidates: [emergencyContactUser],
      );

      expect(matchedUser?.uid, emergencyContactUser.uid);
    });

    test('keeps the preferred linked user when the phone still matches', () {
      final otherUser = UserModel(
        uid: 'contact-2',
        firstName: 'Jane',
        lastName: 'Public',
        email: 'jane@example.com',
        phone: '+1 (555) 123-4567',
        role: UserRole.personal,
        createdAt: DateTime(2025, 1, 1),
      );

      final matchedUser = FirebaseService.selectEmergencyContactUser(
        contactName: 'Dad',
        contactPhone: '+1 555 123 4567',
        candidates: [otherUser, emergencyContactUser],
        preferredUserId: emergencyContactUser.uid,
      );

      expect(matchedUser?.uid, emergencyContactUser.uid);
    });

    test('returns null for ambiguous phone-only emergency contact matches', () {
      final secondEmergencyContactUser = UserModel(
        uid: 'contact-3',
        firstName: 'Jane',
        lastName: 'Doe',
        email: 'jane.doe@example.com',
        phone: '+1 (555) 123-4567',
        role: UserRole.emergencyContact,
        createdAt: DateTime(2025, 1, 1),
      );

      final matchedUser = FirebaseService.selectEmergencyContactUser(
        contactName: 'Dad',
        contactPhone: '+1 555 123 4567',
        candidates: [emergencyContactUser, secondEmergencyContactUser],
      );

      expect(matchedUser, isNull);
    });
  });

  group('Fleet invitation claiming', () {
    final commercialDriver = UserModel(
      uid: 'driver-1',
      firstName: 'Casey',
      lastName: 'Driver',
      email: 'driver@example.com',
      phone: '+1 555 777 8888',
      role: UserRole.commercial,
      createdAt: DateTime(2025, 1, 1),
    );

    test('allows claiming an unlinked invite by exact driver ID', () {
      const fleetDriver = FleetDriver(
        driverId: '',
        name: 'Casey Driver',
        driverUniqueId: '1234567890',
        contactEmail: 'stale@example.com',
      );

      expect(
        FirebaseService.canDriverClaimFleetInvitation(
          fleetDriver: fleetDriver,
          driver: commercialDriver,
          driverCode: '1234567890',
        ),
        isTrue,
      );
    });

    test('rejects claiming an invite already linked to another account', () {
      const fleetDriver = FleetDriver(
        driverId: 'another-driver',
        name: 'Casey Driver',
        driverUniqueId: '1234567890',
        contactEmail: 'driver@example.com',
      );

      expect(
        FirebaseService.canDriverClaimFleetInvitation(
          fleetDriver: fleetDriver,
          driver: commercialDriver,
          driverCode: '1234567890',
        ),
        isFalse,
      );
    });
  });

  group('SOS notification routing', () {
    test('sos reasons also notify linked fleet managers by FCM', () {
      expect(
        EmergencyService.shouldNotifyFleetManagersForReason(
          'SOS triggered by driver in LucidWheels.',
        ),
        isTrue,
      );
      expect(
        EmergencyService.shouldNotifyFleetManagersForReason(
          'Possible accident detected by LucidWheels.',
        ),
        isFalse,
      );
    });
  });
}
