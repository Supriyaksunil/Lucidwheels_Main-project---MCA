import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../providers/auth_provider.dart';
import '../providers/monitoring_provider.dart';
import '../services/face_detection_service.dart';
import '../services/safety_confirmation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/alert_overlay.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/status_indicator.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isInitializingCamera = false;
  bool _isProcessing = false;
  bool _isCameraDisposed = false;
  String? _cameraError;
  StreamSubscription<void>? _safetyConfirmationSub;
  final SafetyConfirmationService _safetyConfirmationService =
      const SafetyConfirmationService();
  final SpeechToText _permissionSpeechToText = SpeechToText();
  bool _isSafetyConfirmationVisible = false;
  bool _isCheckingPermissions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bindSafetyConfirmationListener();
  }

  void _bindSafetyConfirmationListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final monitoringProvider = Provider.of<MonitoringProvider>(
        context,
        listen: false,
      );

      _safetyConfirmationSub?.cancel();
      _safetyConfirmationSub =
          monitoringProvider.safetyConfirmationStream.listen((_) {
        _handleSafetyConfirmation(monitoringProvider);
      });
    });
  }

  Future<void> _handleSafetyConfirmation(
    MonitoringProvider provider,
  ) async {
    if (!mounted || _isSafetyConfirmationVisible) return;

    _isSafetyConfirmationVisible = true;
    try {
      final isSafe = await _safetyConfirmationService.showSafetyConfirmation(
        context,
        enableAudio: true,
      );
      if (!mounted) return;
      await provider.handleSafetyConfirmationResult(isSafe);
    } finally {
      _isSafetyConfirmationVisible = false;
    }
  }

  Future<bool> _ensureMonitoringPermissions() async {
    if (_isCheckingPermissions) {
      return false;
    }

    if (mounted) {
      setState(() {
        _isCheckingPermissions = true;
      });
    } else {
      _isCheckingPermissions = true;
    }

    try {
      final locationReady = await _ensureLocationPermission();
      if (!locationReady) {
        _showMonitoringRequirementMessage(
          'Location permission and location services must be enabled before monitoring. If access was denied earlier, enable it in system settings.',
        );
        return false;
      }

      final microphoneReady = await _ensureMicrophonePermission();
      if (!microphoneReady) {
        _showMonitoringRequirementMessage(
          'Microphone permission is required before monitoring. If access was denied earlier, enable it in system settings.',
        );
        return false;
      }

      await _prepareCameraForMonitoring();
      final cameraReady = _cameraController != null &&
          _cameraController!.value.isInitialized &&
          _isCameraInitialized;
      if (!cameraReady) {
        _showMonitoringRequirementMessage(_cameraPermissionMessage);
        return false;
      }

      return true;
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPermissions = false;
        });
      } else {
        _isCheckingPermissions = false;
      }
    }
  }

  Future<bool> _ensureLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        final enabledAfterSettings =
            await Geolocator.isLocationServiceEnabled();
        if (!enabledAfterSettings) {
          return false;
        }
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      debugPrint('MonitoringScreen: location permission error: $e');
      return false;
    }
  }

  Future<bool> _ensureMicrophonePermission() async {
    try {
      final hadPermission = await _permissionSpeechToText.hasPermission;
      if (!hadPermission) {
        debugPrint('MonitoringScreen: requesting microphone permission');
      }

      final available = await _permissionSpeechToText.initialize(
        onStatus: (_) {},
        onError: (error) {
          debugPrint(
            'MonitoringScreen: speech permission error: ${error.errorMsg}',
          );
        },
      );
      final hasPermission = await _permissionSpeechToText.hasPermission;
      if (_permissionSpeechToText.isListening) {
        await _permissionSpeechToText.stop();
      }
      if (!hasPermission) {
        debugPrint('MonitoringScreen: microphone permission not granted');
      }
      return available && hasPermission;
    } catch (e) {
      debugPrint('MonitoringScreen: microphone permission error: $e');
      return false;
    }
  }

  String get _cameraPermissionMessage {
    final message = (_cameraError ?? '').toLowerCase();
    if (message.contains('accessdenied') ||
        message.contains('permission') ||
        message.contains('denied')) {
      return 'Camera permission is required before monitoring.';
    }
    return 'Camera access is unavailable. Please enable camera permission and try again.';
  }

  void _showMonitoringRequirementMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _initializeCamera() async {
    if (_isInitializingCamera) {
      return;
    }

    if (mounted) {
      setState(() {
        _isInitializingCamera = true;
        _cameraError = null;
        _isCameraDisposed = false;
      });
    } else {
      _isInitializingCamera = true;
      _cameraError = null;
      _isCameraDisposed = false;
    }

    try {
      final cameras = await availableCameras();
      debugPrint('MonitoringScreen: available cameras=${cameras.length}');

      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraError = 'No cameras available on this device/browser.';
            _isCameraInitialized = false;
          });
        } else {
          _cameraError = 'No cameras available on this device/browser.';
          _isCameraInitialized = false;
        }
        return;
      }

      final frontCameras = cameras
          .where((c) => c.lensDirection == CameraLensDirection.front)
          .toList();
      final otherCameras = cameras
          .where((c) => c.lensDirection != CameraLensDirection.front)
          .toList();
      final camerasByPriority = [...frontCameras, ...otherCameras];

      CameraException? lastCameraEx;
      Object? lastError;
      for (final cam in camerasByPriority) {
        try {
          await _disposeCamera(clearError: false, resetDisposedFlag: false);
        } catch (_) {}

        _cameraController = CameraController(
          cam,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: _preferredImageFormatGroup(),
        );

        try {
          await _cameraController!.initialize();
          if (!mounted || _isCameraDisposed) {
            await _disposeCamera(clearError: false);
            return;
          }
          setState(() {
            _isCameraInitialized = true;
            _cameraError = null;
          });
          _startImageStream();
          lastCameraEx = null;
          lastError = null;
          break;
        } on CameraException catch (e) {
          lastCameraEx = e;
          lastError = e;
          await _disposeCamera(clearError: false, resetDisposedFlag: false);
          continue;
        } catch (e) {
          lastError = e;
          await _disposeCamera(clearError: false, resetDisposedFlag: false);
          continue;
        }
      }

      if ((_cameraController == null ||
              !_cameraController!.value.isInitialized) &&
          lastError != null) {
        final message = lastCameraEx != null
            ? 'Camera initialization error: ${lastCameraEx.code} - ${lastCameraEx.description}'
            : 'Camera initialization failed: $lastError';
        if (mounted) {
          setState(() {
            _cameraError = message;
            _isCameraInitialized = false;
          });
        } else {
          _cameraError = message;
          _isCameraInitialized = false;
        }
      }
    } on CameraException catch (e, st) {
      debugPrint('Camera initialization error: $e');
      debugPrint('Stack: $st');
      if (mounted) {
        setState(() {
          _cameraError =
              'Camera initialization error: ${e.code} - ${e.description}';
          _isCameraInitialized = false;
        });
      } else {
        _cameraError =
            'Camera initialization error: ${e.code} - ${e.description}';
        _isCameraInitialized = false;
      }
    } catch (e, st) {
      debugPrint('Camera initialization unexpected error: $e');
      debugPrint('Stack: $st');
      if (mounted) {
        setState(() {
          _cameraError = 'Unexpected camera error: $e';
          _isCameraInitialized = false;
        });
      } else {
        _cameraError = 'Unexpected camera error: $e';
        _isCameraInitialized = false;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializingCamera = false;
        });
      } else {
        _isInitializingCamera = false;
      }
    }
  }

  Future<void> _prepareCameraForMonitoring() async {
    if (_cameraController != null &&
        _cameraController!.value.isInitialized &&
        _isCameraInitialized) {
      if (!_cameraController!.value.isStreamingImages) {
        _startImageStream();
      }
      return;
    }

    _isCameraDisposed = false;
    await _initializeCamera();
  }

  void _retryInitializeCamera() {
    unawaited(_prepareCameraForMonitoring());
  }

  void _startImageStream() {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.isStreamingImages) {
      return;
    }

    _cameraController?.startImageStream((CameraImage image) {
      if (!_isProcessing && mounted) {
        _isProcessing = true;

        try {
          final monitoringProvider = Provider.of<MonitoringProvider>(
            context,
            listen: false,
          );

          if (monitoringProvider.isMonitoring) {
            final sensorOrientation =
                _cameraController!.description.sensorOrientation;
            InputImageRotation rotation;
            switch (sensorOrientation) {
              case 90:
                rotation = InputImageRotation.rotation90deg;
                break;
              case 180:
                rotation = InputImageRotation.rotation180deg;
                break;
              case 270:
                rotation = InputImageRotation.rotation270deg;
                break;
              default:
                rotation = InputImageRotation.rotation0deg;
            }

            monitoringProvider.processCameraFrame(image, rotation);
          }
        } catch (e) {
          debugPrint('Error processing image: $e');
        }

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _isProcessing = false;
          }
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_disposeCamera(clearError: false));
    } else if (state == AppLifecycleState.resumed && mounted) {
      final monitoringProvider = context.read<MonitoringProvider>();
      if (monitoringProvider.isMonitoring) {
        unawaited(_prepareCameraForMonitoring());
      }
    }
  }

  Future<void> _disposeCamera({
    bool clearError = false,
    bool resetDisposedFlag = true,
  }) async {
    final controller = _cameraController;
    _cameraController = null;

    if (controller != null) {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      await controller.dispose();
    }

    _isProcessing = false;
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
        if (clearError) {
          _cameraError = null;
        }
        _isCameraDisposed = resetDisposedFlag;
      });
    } else {
      _isCameraInitialized = false;
      if (clearError) {
        _cameraError = null;
      }
      _isCameraDisposed = resetDisposedFlag;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _safetyConfirmationSub?.cancel();
    unawaited(_disposeCamera(clearError: false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monitoringProvider = Provider.of<MonitoringProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildCameraSurface(monitoringProvider.isMonitoring),
          ),
          if (monitoringProvider.isMonitoring &&
              _isCameraInitialized &&
              _cameraController != null)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final state = monitoringProvider.currentState;
                  final bbox = state.boundingBox;
                  final imgSize = state.imageSize;

                  if (bbox == null || imgSize == null) {
                    return const SizedBox.shrink();
                  }

                  final scaleX = constraints.maxWidth / imgSize.width;
                  final scaleY = constraints.maxHeight / imgSize.height;

                  final isFrontCamera =
                      _cameraController!.description.lensDirection ==
                          CameraLensDirection.front;
                  final left = isFrontCamera
                      ? constraints.maxWidth - (bbox.right * scaleX)
                      : bbox.left * scaleX;
                  final top = bbox.top * scaleY;
                  final width = bbox.width * scaleX;
                  final height = bbox.height * scaleY;

                  return Stack(
                    children: [
                      Positioned(
                        left: left,
                        top: top,
                        child: Container(
                          width: width,
                          height: height,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF9AE6B4),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.62),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Text(
                        'LucidWheels Monitor',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (monitoringProvider.isMonitoring)
                      const StatusIndicator(
                        label: 'LIVE',
                        icon: Icons.fiber_manual_record,
                        color: AppTheme.accentRed,
                        compact: true,
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 92,
            left: 16,
            child: _buildStatusIndicator(monitoringProvider),
          ),
          if (monitoringProvider.isMonitoring)
            Positioned(
              top: 92,
              right: 16,
              child: _buildDiagnosticsCard(monitoringProvider.currentState),
            ),
          if (monitoringProvider.isMonitoring &&
              monitoringProvider.isAlertOverlayVisible)
            AlertOverlay(
              title: 'ALERT',
              message: _buildAlertMessage(monitoringProvider),
              onAcknowledge: () {
                monitoringProvider.acknowledgeCurrentAlert();
              },
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (monitoringProvider.isMonitoring) ...[
                    CustomButton(
                      label: 'Emergency Stop',
                      icon: Icons.emergency,
                      backgroundColor: AppTheme.accentRed,
                      onPressed: () => _showEmergencyDialog(monitoringProvider),
                    ),
                    const SizedBox(height: 10),
                  ],
                  CustomButton(
                    label: monitoringProvider.isMonitoring
                        ? 'Stop Monitoring'
                        : 'Start Monitoring',
                    icon: monitoringProvider.isMonitoring
                        ? Icons.stop_circle_rounded
                        : Icons.play_circle_fill_rounded,
                    backgroundColor: monitoringProvider.isMonitoring
                        ? const Color(0xFFF57C00)
                        : AppTheme.primaryBlue,
                    isLoading:
                        (_isCheckingPermissions || _isInitializingCamera) &&
                            !monitoringProvider.isMonitoring,
                    onPressed: (_isInitializingCamera || _isCheckingPermissions)
                        ? null
                        : () => _toggleMonitoring(
                              monitoringProvider,
                              user?.uid ?? '',
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraSurface(bool isMonitoring) {
    if (isMonitoring && _isCameraInitialized && _cameraController != null) {
      return CameraPreview(_cameraController!);
    }

    if (!isMonitoring) {
      return DecoratedBox(
        decoration: AppTheme.backgroundDecoration,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam_off_rounded, color: Colors.white, size: 44),
                SizedBox(height: 10),
                Text(
                  'Camera and face detection stay off until you tap Start Monitoring.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isInitializingCamera) {
      return DecoratedBox(
        decoration: AppTheme.backgroundDecoration,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _buildCameraFallback();
  }

  Widget _buildCameraFallback() {
    final message = _cameraError ??
        'Camera preview is unavailable right now. Monitoring can continue with limited detection.';

    return DecoratedBox(
      decoration: AppTheme.backgroundDecoration,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_rounded,
                  color: Colors.white, size: 44),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    label: 'Retry Camera',
                    icon: Icons.refresh_rounded,
                    onPressed: _retryInitializeCamera,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(MonitoringProvider provider) {
    if (!provider.isMonitoring) {
      return const StatusIndicator(
        label: 'Standby',
        icon: Icons.power_settings_new_rounded,
        color: Colors.white70,
      );
    }
    if (provider.currentState.isDrowsy) {
      return const StatusIndicator(
        label: 'Drowsy',
        icon: Icons.warning_amber_rounded,
        color: AppTheme.accentRed,
      );
    }
    if (provider.currentState.isDistracted) {
      return const StatusIndicator(
        label: 'Distracted',
        icon: Icons.visibility_off_rounded,
        color: Color(0xFFFFB74D),
      );
    }
    if (provider.currentState.isFaceDetected) {
      return const StatusIndicator(
        label: 'Focused',
        icon: Icons.check_circle_rounded,
        color: Color(0xFF4CAF50),
      );
    }
    return const StatusIndicator(
      label: 'No Face',
      icon: Icons.face_retouching_off,
      color: Color(0xFFFFEE58),
    );
  }

  Future<void> _toggleMonitoring(
    MonitoringProvider provider,
    String userId,
  ) async {
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (provider.isMonitoring) {
      await provider.stopMonitoring();
      await _disposeCamera(clearError: true);
      return;
    }

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Eye-closure and head-tilt detection are supported on Android/iOS. Web preview is limited.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }

    final permissionsReady = await _ensureMonitoringPermissions();
    if (!permissionsReady || !mounted) {
      return;
    }

    await provider.startMonitoring(userId);

    if (_cameraError != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Monitoring started, but camera preview is unavailable: $_cameraError',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showEmergencyDialog(MonitoringProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Text('Emergency Alert'),
        content: const Text(
          'This will trigger an accident alert and notify emergency contacts. Continue?',
        ),
        actionsOverflowDirection: VerticalDirection.down,
        actionsOverflowButtonSpacing: 8,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          CustomButton(
            label: 'Confirm Emergency',
            backgroundColor: AppTheme.accentRed,
            onPressed: () async {
              Navigator.pop(dialogContext);
              await provider.reportAccident(
                reason: 'SOS triggered by driver in LucidWheels.',
              );
              if (!mounted) {
                return;
              }
              _showAccidentReportedDialog();
            },
          ),
        ],
      ),
    );
  }

  String _buildAlertMessage(MonitoringProvider provider) {
    if ((provider.activeAlertMessage ?? '').isNotEmpty) {
      return provider.activeAlertMessage!;
    }
    if (provider.currentState.isDrowsy) {
      return 'Eyes closed for too long\nPlease wake up and stay attentive';
    }
    return 'Driver alert triggered\nPlease stay attentive';
  }

  ImageFormatGroup _preferredImageFormatGroup() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return ImageFormatGroup.nv21;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return ImageFormatGroup.bgra8888;
    }
    return ImageFormatGroup.yuv420;
  }

  Widget _buildDiagnosticsCard(DriverState state) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _diag('face', state.isFaceDetected.toString()),
          _diag('eyes', state.eyeOpenness.toStringAsFixed(2)),
          _diag('drowsy', state.isDrowsy.toString()),
          _diag('tilt', state.isDistracted.toString()),
          _diag('alert', state.isAlert.toString()),
          _diag('headY', state.headRotationY.toStringAsFixed(1)),
          _diag('headZ', state.headRotationZ.toStringAsFixed(1)),
        ],
      ),
    );
  }

  Widget _diag(String label, String value) {
    return Text(
      '$label: $value',
      style: const TextStyle(color: Colors.white70, fontSize: 11),
    );
  }

  void _showAccidentReportedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: const Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(Icons.emergency_rounded, color: AppTheme.accentRed),
            Text('Emergency Reported'),
          ],
        ),
        content: const Text(
          'Your accident alert has been sent to emergency services and your contacts. Stay calm and wait for assistance.',
        ),
        actions: [
          CustomButton(
            label: 'OK',
            onPressed: () {
              Navigator.pop(dialogContext);
              Provider.of<MonitoringProvider>(context, listen: false)
                  .stopMonitoring();
              unawaited(_disposeCamera(clearError: true));
            },
          ),
        ],
      ),
    );
  }
}
