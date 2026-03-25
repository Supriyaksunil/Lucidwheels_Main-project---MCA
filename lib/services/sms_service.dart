import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class SmsService {
  Future<void> openSmsFallback(
    List<String> numbers,
    double lat,
    double lng,
  ) async {
    final recipients = numbers
        .map(_normalizePhone)
        .where((number) => number.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (recipients.isEmpty) {
      return;
    }

    final message =
        '?? Emergency Alert\nLocation: https://maps.google.com/?q=$lat,$lng';
    final encodedMessage = Uri.encodeComponent(message);
    final recipientList = recipients.join(',');

    final candidates = <Uri>[
      Uri.parse('sms:$recipientList?body=$encodedMessage'),
      Uri.parse('smsto:$recipientList?body=$encodedMessage'),
    ];

    for (final uri in candidates) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
        if (launched) {
          return;
        }
      } catch (error) {
        debugPrint(
          'SmsService: failed to open SMS fallback for $recipientList: $error',
        );
      }
    }

    throw Exception('Could not open SMS app for $recipientList');
  }

  Future<bool> sendEmergencySMS(
    String phoneNumber,
    double latitude,
    double longitude, {
    String reason = 'Possible accident detected.',
  }) async {
    try {
      await openSmsFallback([phoneNumber], latitude, longitude);
      return true;
    } catch (error) {
      debugPrint(
        'SmsService: emergency SMS fallback failed for $phoneNumber: $error',
      );
      return false;
    }
  }

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[^0-9+]'), '');
  }
}
