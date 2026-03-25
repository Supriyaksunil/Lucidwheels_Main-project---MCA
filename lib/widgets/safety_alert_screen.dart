import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vibration/vibration.dart';

import '../theme/app_theme.dart';
import 'common/custom_button.dart';

@visibleForTesting
String normalizeSafetyConfirmationSpeech(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z\s']"), ' ')
      .replaceAll(RegExp(r"\bi\s*'?m\b"), 'i am')
      .replaceAll(RegExp(r'\bi\s+m\b'), 'i am')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

@visibleForTesting
bool matchesSafetyConfirmationPhrase(String value) {
  final normalized = normalizeSafetyConfirmationSpeech(value);
  if (normalized.isEmpty) {
    return false;
  }
  return RegExp(r'\byes\b').hasMatch(normalized) ||
      normalized.contains('i am safe');
}

class SafetyAlertScreen extends StatefulWidget {
  final int countdownSeconds;
  final bool enableAudio;

  const SafetyAlertScreen({
    super.key,
    this.countdownSeconds = 30,
    this.enableAudio = false,
  });

  @override
  State<SafetyAlertScreen> createState() => _SafetyAlertScreenState();
}

class _SafetyAlertScreenState extends State<SafetyAlertScreen> {
  final SpeechToText _speechToText = SpeechToText();
  final AudioPlayer _alarmPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();

  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _isFinalizing = false;
  bool _voiceAvailable = false;
  LocaleName? _listeningLocale;
  String _voiceStatus = 'Starting safety confirmation...';

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.countdownSeconds;
    unawaited(_startSafetyFlow());
  }

  Future<void> _startSafetyFlow() async {
    _startCountdown();
    await _triggerVibrationAndHaptics();
    await _startVoiceRecognition();

    if (widget.enableAudio) {
      await _playAlarmSound();
      await _playVoicePrompt();
    }

    if (_voiceAvailable && !_isFinalizing) {
      await _listenForSafePhrase();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isFinalizing) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        setState(() => _remainingSeconds = 0);
        timer.cancel();
        unawaited(_finalizeConfirmation(false));
        return;
      }

      setState(() => _remainingSeconds -= 1);
    });
  }

  Future<void> _triggerVibrationAndHaptics() async {
    HapticFeedback.heavyImpact();

    if (kIsWeb) return;

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(pattern: [0, 240, 140, 240, 140, 260]);
      }
    } catch (e) {
      debugPrint('SafetyAlertScreen: vibration error: $e');
    }
  }

  Future<void> _playAlarmSound() async {
    try {
      await _alarmPlayer.stop();
      await _alarmPlayer.setReleaseMode(ReleaseMode.stop);
      await _alarmPlayer.setVolume(0.85);
      if (kIsWeb) {
        await _alarmPlayer.play(UrlSource('assets/sounds/emergency_alert.mp3'));
      } else {
        await _alarmPlayer.play(AssetSource('sounds/emergency_alert.mp3'));
      }
      await Future.delayed(const Duration(milliseconds: 1200));
      await _alarmPlayer.stop();
    } catch (e) {
      debugPrint('SafetyAlertScreen: alarm playback error: $e');
      SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> _playVoicePrompt() async {
    try {
      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.stop();
      await _flutterTts.speak(
        'Are you safe? Say YES to cancel emergency alert.',
      );
    } catch (e) {
      debugPrint('SafetyAlertScreen: voice prompt error: $e');
    }
  }

  Future<void> _startVoiceRecognition() async {
    try {
      final hadPermission = await _speechToText.hasPermission;
      if (!hadPermission) {
        debugPrint('SafetyAlertScreen: requesting microphone permission');
      }

      final available = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: (error) {
          debugPrint('SafetyAlertScreen: speech error: ${error.errorMsg}');
          if (!mounted || _isFinalizing) return;
          setState(() {
            _voiceStatus = error.errorMsg.toLowerCase().contains('permission')
                ? 'Microphone permission is required. Tap "I am safe" to cancel or enable it in settings.'
                : 'Voice recognition unavailable. Tap "I am safe" to cancel.';
          });
        },
      );
      final hasPermission = await _speechToText.hasPermission;
      final listeningLocale =
          available && hasPermission ? await _resolveListeningLocale() : null;

      if (!mounted || _isFinalizing) return;

      setState(() {
        _listeningLocale = listeningLocale;
        _voiceAvailable = available && hasPermission;
        _voiceStatus = _voiceAvailable
            ? 'Listening for "yes" or "I am safe"...'
            : hadPermission
                ? 'Voice recognition unavailable. Tap "I am safe" to cancel.'
                : 'Microphone permission is required. Tap "I am safe" to cancel or enable it in settings.';
      });
    } catch (e) {
      debugPrint('SafetyAlertScreen: speech init failed: $e');
      if (!mounted || _isFinalizing) return;
      setState(() {
        _listeningLocale = null;
        _voiceAvailable = false;
        _voiceStatus = 'Voice confirmation failed. Tap "I am safe" to cancel.';
      });
    }
  }

  Future<LocaleName?> _resolveListeningLocale() async {
    try {
      final locales = await _speechToText.locales();
      for (final preferredLocale in const ['en_US', 'en_IN', 'en_GB']) {
        for (final locale in locales) {
          if (locale.localeId == preferredLocale) {
            return locale;
          }
        }
      }
      for (final locale in locales) {
        if (locale.localeId.toLowerCase().startsWith('en')) {
          return locale;
        }
      }
      return await _speechToText.systemLocale();
    } catch (e) {
      debugPrint('SafetyAlertScreen: failed to resolve speech locale: $e');
      return null;
    }
  }

  void _onSpeechStatus(String status) {
    if (!_voiceAvailable || _isFinalizing || _remainingSeconds <= 0) {
      return;
    }

    if (status == SpeechToText.notListeningStatus ||
        status == SpeechToText.doneStatus) {
      unawaited(_listenForSafePhrase());
    }
  }

  Future<void> _listenForSafePhrase() async {
    if (!_voiceAvailable || _isFinalizing || _speechToText.isListening) {
      return;
    }

    try {
      final listenForSeconds =
          _remainingSeconds > 0 ? _remainingSeconds : widget.countdownSeconds;
      await _alarmPlayer.stop();
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: Duration(seconds: listenForSeconds),
        pauseFor: const Duration(seconds: 2),
        localeId: _listeningLocale?.localeId,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.confirmation,
          partialResults: true,
          cancelOnError: false,
        ),
      );
    } catch (e) {
      debugPrint('SafetyAlertScreen: speech listen failed: $e');
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final spokenRaw = result.recognizedWords.trim();
    if (spokenRaw.isEmpty) return;

    final spokenNormalized = normalizeSafetyConfirmationSpeech(spokenRaw);
    if (spokenNormalized.isEmpty) return;

    if (matchesSafetyConfirmationPhrase(spokenNormalized)) {
      debugPrint(
          'SafetyAlertScreen: safe phrase detected -> $spokenNormalized');
      unawaited(_finalizeConfirmation(true));
    }
  }

  Future<void> _finalizeConfirmation(bool isSafe) async {
    if (_isFinalizing) return;
    _isFinalizing = true;

    _countdownTimer?.cancel();
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
    } catch (_) {}

    try {
      await _flutterTts.stop();
    } catch (_) {}

    try {
      await _alarmPlayer.stop();
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(isSafe);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    unawaited(_speechToText.stop());
    unawaited(_flutterTts.stop());
    unawaited(_alarmPlayer.stop());
    _alarmPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCriticalWindow = _remainingSeconds <= 5;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isCriticalWindow
                      ? AppTheme.accentRed
                      : AppTheme.accentRed.withValues(alpha: 0.6),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentRed.withValues(alpha: 0.28),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 84,
                      color: AppTheme.accentRed,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Possible accident detected. Are you safe?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Emergency alert will be sent in ${_remainingSeconds}s',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isCriticalWindow
                            ? AppTheme.accentRed
                            : Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.3),
                        border: Border.all(
                          color: isCriticalWindow
                              ? AppTheme.accentRed
                              : Colors.white38,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$_remainingSeconds',
                        style: TextStyle(
                          color: isCriticalWindow
                              ? AppTheme.accentRed
                              : Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _voiceStatus,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Are you safe? Say YES to cancel emergency alert.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: 'I am safe',
                        icon: Icons.check_circle_rounded,
                        backgroundColor: const Color(0xFF2E7D32),
                        onPressed: () {
                          unawaited(_finalizeConfirmation(true));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
