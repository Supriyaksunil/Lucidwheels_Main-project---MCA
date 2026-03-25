import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../models/monitoring_session_model.dart';

class AlertService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlerting = false;
  AlertType? _currentAlertType;

  final StreamController<AlertType> _alertController =
      StreamController<AlertType>.broadcast();
  Stream<AlertType> get alertStream => _alertController.stream;

  Future<bool> triggerAlert(
    AlertType type,
    Severity severity, {
    bool playSound = true,
    bool allowTakeover = false,
  }) async {
    debugPrint('AlertService: triggering alert for $type');

    if (_isAlerting) {
      if (_currentAlertType == type) {
        debugPrint(
            'AlertService: $type is already active, ignoring duplicate trigger');
        return false;
      }
      if (!allowTakeover) {
        debugPrint(
          'AlertService: ignoring $type because $_currentAlertType is already active',
        );
        return false;
      }
      await stopAlert();
    }

    _isAlerting = true;
    _currentAlertType = type;
    _alertController.add(type);

    await _triggerHaptic(severity);
    if (playSound) {
      await _playAlertSound(type, severity);
    }
    return true;
  }

  Future<void> _triggerHaptic(Severity severity) async {
    final hasVibrator = await Vibration.hasVibrator();
    if (!kIsWeb && hasVibrator == true) {
      switch (severity) {
        case Severity.low:
          await Vibration.vibrate(duration: 500);
          break;
        case Severity.medium:
          await Vibration.vibrate(pattern: [500, 1000, 500]);
          break;
        case Severity.high:
          await Vibration.vibrate(pattern: [200, 200, 200, 200, 200, 200]);
          break;
        case Severity.critical:
          await Vibration.vibrate(
            pattern: [100, 100, 100, 100, 100, 100, 100, 100],
          );
          break;
      }
    }

    switch (severity) {
      case Severity.low:
        HapticFeedback.lightImpact();
        break;
      case Severity.medium:
        HapticFeedback.mediumImpact();
        break;
      case Severity.high:
      case Severity.critical:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  Future<void> _playAlertSound(AlertType type, Severity severity) async {
    String soundAsset;
    switch (type) {
      case AlertType.drowsiness:
        soundAsset = 'sounds/drowsiness_alert.mp3';
        break;
      case AlertType.distraction:
        soundAsset = 'sounds/distraction_alert.mp3';
        break;
      case AlertType.accident:
        soundAsset = 'sounds/emergency_alert.mp3';
        break;
      case AlertType.fatigue:
        soundAsset = 'sounds/fatigue_alert.mp3';
        break;
    }

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      if (kIsWeb) {
        try {
          await _audioPlayer.play(UrlSource('assets/$soundAsset'));
        } catch (e) {
          debugPrint('AlertService: web audio play failed: $e');
          SystemSound.play(SystemSoundType.alert);
        }
      } else {
        await _audioPlayer.play(AssetSource(soundAsset));
      }
    } catch (e) {
      debugPrint('AlertService: audio playback error: $e');
      SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> stopAlert() async {
    _isAlerting = false;
    _currentAlertType = null;
    await _audioPlayer.stop();
  }

  Future<bool> triggerEmergencyAlert({
    bool playSound = true,
    bool allowTakeover = false,
  }) async {
    final didStart = await triggerAlert(
      AlertType.accident,
      Severity.critical,
      playSound: playSound,
      allowTakeover: allowTakeover,
    );
    if (didStart) {
      await _playEmergencySequence();
    }
    return didStart;
  }

  Future<void> _playEmergencySequence() async {
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(seconds: 2));
      if (!_isAlerting) {
        break;
      }
      if (!kIsWeb) {
        await Vibration.vibrate(duration: 1000);
      }
    }
  }

  bool get isAlerting => _isAlerting;

  void dispose() {
    _audioPlayer.dispose();
    _alertController.close();
  }
}
