import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableTracking: true,
      enableClassification: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  bool _isProcessing = false;
  DateTime? _eyesClosedStartTime;
  DateTime? _noFaceStartTime;
  DateTime? _headTiltStartTime;

  static const double eyeClosedThreshold = 0.3;
  static const double lowEyeVisibilityThreshold = 0.5;
  static const double headTiltThresholdDegrees = 20.0;

  static const int drowsinessThresholdSeconds = 3;
  static const int noFaceThresholdSeconds = 5;
  static const int headTiltThresholdSeconds = 5;

  final StreamController<DriverState> _stateController =
      StreamController<DriverState>.broadcast();
  Stream<DriverState> get stateStream => _stateController.stream;

  Future<void> processImage(
      CameraImage image, InputImageRotation rotation) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final inputImage = _convertCameraImage(image, rotation);
      if (inputImage == null) {
        debugPrint('FaceDetectionService: convertCameraImage returned null');
        _emitNoFaceState();
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _emitNoFaceState();
        return;
      }

      final face = faces.first;
      _analyzeFace(face, inputImage.metadata?.size);
    } catch (e) {
      debugPrint('FaceDetectionService: error processing image: $e');
      _emitNoFaceState();
    } finally {
      _isProcessing = false;
    }
  }

  void _emitNoFaceState() {
    _noFaceStartTime ??= DateTime.now();
    final noFaceDuration = DateTime.now().difference(_noFaceStartTime!);
    final isNoFaceAlert = noFaceDuration.inSeconds >= noFaceThresholdSeconds;

    _eyesClosedStartTime = null;
    _headTiltStartTime = null;

    _stateController.add(
      DriverState(
        isFaceDetected: false,
        eyeOpenness: 0.0,
        isAlert: isNoFaceAlert,
        isDrowsy: false,
        isDistracted: false,
      ),
    );
  }

  InputImage? _convertCameraImage(
      CameraImage image, InputImageRotation rotation) {
    try {
      final imageSize = Size(image.width.toDouble(), image.height.toDouble());
      late final Uint8List bytes;
      late final InputImageFormat inputImageFormat;
      late final int bytesPerRow;

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        bytes = _androidImageToNv21(image);
        inputImageFormat = InputImageFormat.nv21;
        bytesPerRow = image.width;
      } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        bytes = image.planes.first.bytes;
        inputImageFormat = InputImageFormat.bgra8888;
        bytesPerRow = image.planes.first.bytesPerRow;
      } else {
        final writeBuffer = WriteBuffer();
        for (final plane in image.planes) {
          writeBuffer.putUint8List(plane.bytes);
        }
        bytes = writeBuffer.done().buffer.asUint8List();
        final detectedFormat =
            InputImageFormatValue.fromRawValue(image.format.raw);
        if (detectedFormat == null) return null;
        inputImageFormat = detectedFormat;
        bytesPerRow = image.planes.first.bytesPerRow;
      }

      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: inputImageFormat,
        bytesPerRow: bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData,
      );
    } catch (e) {
      debugPrint('FaceDetectionService: convertCameraImage error: $e');
      return null;
    }
  }

  Uint8List _androidImageToNv21(CameraImage image) {
    if (image.planes.length == 1) {
      return image.planes.first.bytes;
    }

    final width = image.width;
    final height = image.height;
    final ySize = width * height;
    final uvSize = width * height ~/ 4;
    final nv21 = Uint8List(ySize + uvSize * 2);

    final yPlane = image.planes[0];
    int position = 0;
    for (int row = 0; row < height; row++) {
      final rowStart = row * yPlane.bytesPerRow;
      nv21.setRange(position, position + width, yPlane.bytes, rowStart);
      position += width;
    }

    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final uRowStride = uPlane.bytesPerRow;
    final vRowStride = vPlane.bytesPerRow;
    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;

    for (int row = 0; row < height ~/ 2; row++) {
      for (int col = 0; col < width ~/ 2; col++) {
        final uIndex = row * uRowStride + col * uPixelStride;
        final vIndex = row * vRowStride + col * vPixelStride;
        nv21[position++] = vPlane.bytes[vIndex];
        nv21[position++] = uPlane.bytes[uIndex];
      }
    }

    return nv21;
  }

  void _analyzeFace(Face face, Size? imageSize) {
    _noFaceStartTime = null;

    final eyeProbabilities = <double>[
      if (face.leftEyeOpenProbability != null) face.leftEyeOpenProbability!,
      if (face.rightEyeOpenProbability != null) face.rightEyeOpenProbability!,
    ];

    final avgEyeOpen = eyeProbabilities.isEmpty
        ? 0.0
        : eyeProbabilities.reduce((a, b) => a + b) / eyeProbabilities.length;

    final headEulerAngleY = face.headEulerAngleY ?? 0.0;
    final headEulerAngleZ = face.headEulerAngleZ ?? 0.0;

    final isEyesClosed = avgEyeOpen < eyeClosedThreshold;
    if (isEyesClosed) {
      _eyesClosedStartTime ??= DateTime.now();
    } else {
      _eyesClosedStartTime = null;
    }

    final eyesClosedDuration = _eyesClosedStartTime == null
        ? Duration.zero
        : DateTime.now().difference(_eyesClosedStartTime!);
    final isDrowsinessAlert = isEyesClosed &&
        eyesClosedDuration.inSeconds >= drowsinessThresholdSeconds;

    final isHeadTilted = headEulerAngleY.abs() >= headTiltThresholdDegrees ||
        headEulerAngleZ.abs() >= headTiltThresholdDegrees;
    final isTiltWithLowEye =
        isHeadTilted && avgEyeOpen < lowEyeVisibilityThreshold;
    if (isTiltWithLowEye) {
      _headTiltStartTime ??= DateTime.now();
    } else {
      _headTiltStartTime = null;
    }

    final headTiltDuration = _headTiltStartTime == null
        ? Duration.zero
        : DateTime.now().difference(_headTiltStartTime!);
    final isHeadTiltAlert = isTiltWithLowEye &&
        headTiltDuration.inSeconds >= headTiltThresholdSeconds;

    final isAlert = isDrowsinessAlert || isHeadTiltAlert;

    debugPrint(
      'FaceDetectionService: eyeOpen=${avgEyeOpen.toStringAsFixed(2)} '
      'eyesClosedMs=${eyesClosedDuration.inMilliseconds} '
      'headY=${headEulerAngleY.toStringAsFixed(1)} '
      'headZ=${headEulerAngleZ.toStringAsFixed(1)} '
      'headTiltMs=${headTiltDuration.inMilliseconds} '
      'isAlert=$isAlert',
    );

    _stateController.add(
      DriverState(
        isFaceDetected: true,
        eyeOpenness: avgEyeOpen,
        isDrowsy: isDrowsinessAlert,
        isDistracted: isHeadTiltAlert,
        headRotationY: headEulerAngleY,
        headRotationZ: headEulerAngleZ,
        isAlert: isAlert,
        boundingBox: face.boundingBox,
        imageSize: imageSize,
      ),
    );
  }

  void dispose() {
    _faceDetector.close();
    _stateController.close();
  }
}

class DriverState {
  final bool isFaceDetected;
  final double eyeOpenness;
  final bool isDrowsy;
  final bool isDistracted;
  final double headRotationY;
  final double headRotationZ;
  final bool isAlert;
  final Rect? boundingBox;
  final Size? imageSize;

  DriverState({
    this.isFaceDetected = false,
    this.eyeOpenness = 1.0,
    this.isDrowsy = false,
    this.isDistracted = false,
    this.headRotationY = 0,
    this.headRotationZ = 0,
    this.isAlert = false,
    this.boundingBox,
    this.imageSize,
  });

  DriverState copyWith({
    bool? isFaceDetected,
    double? eyeOpenness,
    bool? isDrowsy,
    bool? isDistracted,
    double? headRotationY,
    double? headRotationZ,
    bool? isAlert,
    Rect? boundingBox,
    Size? imageSize,
  }) {
    return DriverState(
      isFaceDetected: isFaceDetected ?? this.isFaceDetected,
      eyeOpenness: eyeOpenness ?? this.eyeOpenness,
      isDrowsy: isDrowsy ?? this.isDrowsy,
      isDistracted: isDistracted ?? this.isDistracted,
      headRotationY: headRotationY ?? this.headRotationY,
      headRotationZ: headRotationZ ?? this.headRotationZ,
      isAlert: isAlert ?? this.isAlert,
      boundingBox: boundingBox ?? this.boundingBox,
      imageSize: imageSize ?? this.imageSize,
    );
  }
}
