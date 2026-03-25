import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class CallService {
  Future<void> callEmergencyContacts(
    List<String> numbers, {
    Duration delay = const Duration(seconds: 7),
  }) async {
    final uniqueNumbers = numbers
        .map(_normalizePhone)
        .where((number) => number.isNotEmpty)
        .toSet()
        .toList(growable: false);

    for (var index = 0; index < uniqueNumbers.length; index++) {
      final number = uniqueNumbers[index];
      try {
        final launched = await launchUrl(
          Uri.parse('tel:$number'),
          mode: LaunchMode.externalNonBrowserApplication,
        );
        if (!launched) {
          debugPrint('CallService: could not launch dialer for $number');
        }
      } catch (error) {
        debugPrint('CallService: failed to call $number: $error');
      }

      if (index < uniqueNumbers.length - 1 && delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
    }
  }

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[^0-9+]'), '');
  }
}
