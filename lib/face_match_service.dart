import 'dart:convert';
import 'package:http/http.dart' as http;

class FaceValidationResult {
  final bool isValid;
  final String message;
  final double faceQuality;
  final double blur;
  final double yaw;
  final double pitch;
  final double faceAreaRatio;

  const FaceValidationResult({
    required this.isValid,
    required this.message,
    this.faceQuality = 0,
    this.blur = 0,
    this.yaw = 0,
    this.pitch = 0,
    this.faceAreaRatio = 0,
  });
}

class FaceMatchService {
  static const String _apiKey = '7tStA3D_kKf5r2QS5F5IphkGQUlsO1Am';
  static const String _apiSecret = 'P9RMbJfTjj9gwC94juQ46MwgstV8VGMG';
  static const String _apiUrl =
      'https://api-us.faceplusplus.com/facepp/v3/compare';
  static const String _detectUrl =
      'https://api-us.faceplusplus.com/facepp/v3/detect';
  static const Duration _requestTimeout = Duration(seconds: 12);
  static const double _samePersonThreshold = 80.0;
  static const double _livenessMinContinuity = 70.0;
  static const double _suspiciouslyStaticContinuity = 99.9;
  static const double _minPoseDeltaForStaticGuard = 0.8;

  static Future<double> compareFaces({
    required String webcamBase64,
    required String storedPhotoUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        body: {
          'api_key': _apiKey,
          'api_secret': _apiSecret,
          'image_base64_1': webcamBase64,
          'image_url2': storedPhotoUrl,
        },
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['confidence'] == null) {
          throw Exception('No face detected in one or both photos');
        }
        return (data['confidence'] as num).toDouble();
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception('Face++ error: ${error['error_message']}');
      }
    } catch (e) {
      throw Exception('Face match failed: $e');
    }
  }

  static Future<double> compareCapturedFrames({
    required String frameBase64A,
    required String frameBase64B,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        body: {
          'api_key': _apiKey,
          'api_secret': _apiSecret,
          'image_base64_1': frameBase64A,
          'image_base64_2': frameBase64B,
        },
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['confidence'] == null) {
          throw Exception('No comparable face in one or both frames');
        }
        return (data['confidence'] as num).toDouble();
      }

      final error = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception('Face++ error: ${error['error_message']}');
    } catch (e) {
      throw Exception('Frame continuity check failed: $e');
    }
  }

  static bool isSamePerson(double confidence) => confidence >= _samePersonThreshold;

  static Future<FaceValidationResult> validateFaceFrame({
    required String imageBase64,
    bool strict = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_detectUrl),
        body: {
          'api_key': _apiKey,
          'api_secret': _apiSecret,
          'image_base64': imageBase64,
          'return_attributes': 'facequality,blur,headpose',
        },
      ).timeout(_requestTimeout);

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        return FaceValidationResult(
          isValid: false,
          message:
              'Face detect failed: ${error['error_message'] ?? 'Unknown error'}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final faces =
          (data['faces'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      if (faces.isEmpty) {
        return const FaceValidationResult(
          isValid: false,
          message: 'No face detected. Please center your face in the camera.',
        );
      }

      if (faces.length > 1) {
        return const FaceValidationResult(
          isValid: false,
          message:
              'Multiple faces detected. Only one person should be in frame.',
        );
      }

      final attributes =
          faces.first['attributes'] as Map<String, dynamic>? ?? {};
      final faceRect =
          faces.first['face_rectangle'] as Map<String, dynamic>? ?? {};
      final imageWidth = _toDouble(data['image_width']);
      final imageHeight = _toDouble(data['image_height']);

      final faceQuality = _toDouble(attributes['facequality']?['value']);
      final blur = _toDouble(attributes['blur']?['blurness']?['value']);
      final yaw = _toDouble(attributes['headpose']?['yaw_angle']).abs().toDouble();
      final pitch = _toDouble(attributes['headpose']?['pitch_angle']).abs().toDouble();
      final faceWidth = _toDouble(faceRect['width']);
      final faceHeight = _toDouble(faceRect['height']);
      final faceAreaRatio = imageWidth > 0 && imageHeight > 0
          ? (faceWidth * faceHeight) / (imageWidth * imageHeight)
          : 0.0;

      final minQuality = strict ? 75.0 : 50.0;
      final maxBlur = strict ? 60.0 : 75.0;
      final maxPose = strict ? 20.0 : 28.0;
      final minFaceArea = strict ? 0.08 : 0.045;

      if (faceQuality > 0 && faceQuality < minQuality) {
        return FaceValidationResult(
          isValid: false,
          message:
              'Face quality is too low (${faceQuality.toStringAsFixed(0)}). Improve lighting and move closer.',
          faceQuality: faceQuality,
          blur: blur,
          yaw: yaw,
          pitch: pitch,
          faceAreaRatio: faceAreaRatio,
        );
      }

      if (blur > 0 && blur > maxBlur) {
        return FaceValidationResult(
          isValid: false,
          message: 'Image is too blurry. Hold still and try again.',
          faceQuality: faceQuality,
          blur: blur,
          yaw: yaw,
          pitch: pitch,
          faceAreaRatio: faceAreaRatio,
        );
      }

      if (yaw > maxPose || pitch > maxPose) {
        return FaceValidationResult(
          isValid: false,
          message: 'Face angle too steep. Look straight at the camera.',
          faceQuality: faceQuality,
          blur: blur,
          yaw: yaw,
          pitch: pitch,
          faceAreaRatio: faceAreaRatio,
        );
      }

      if (faceAreaRatio > 0 && faceAreaRatio < minFaceArea) {
        return FaceValidationResult(
          isValid: false,
          message: 'Move closer so your face fills more of the frame.',
          faceQuality: faceQuality,
          blur: blur,
          yaw: yaw,
          pitch: pitch,
          faceAreaRatio: faceAreaRatio,
        );
      }

      return FaceValidationResult(
        isValid: true,
        message: 'Face quality check passed.',
        faceQuality: faceQuality,
        blur: blur,
        yaw: yaw,
        pitch: pitch,
        faceAreaRatio: faceAreaRatio,
      );
    } catch (e) {
      return FaceValidationResult(
        isValid: false,
        message: 'Face validation failed: $e',
      );
    }
  }

  static Future<FaceValidationResult> validateLivenessPair({
    required String frameBase64A,
    required String frameBase64B,
    required FaceValidationResult frameAValidation,
    required FaceValidationResult frameBValidation,
  }) async {
    try {
      final continuity = await compareCapturedFrames(
        frameBase64A: frameBase64A,
        frameBase64B: frameBase64B,
      );

      final poseDelta =
          (frameAValidation.yaw - frameBValidation.yaw).abs().toDouble() +
            (frameAValidation.pitch - frameBValidation.pitch).abs().toDouble();

      if (continuity < _livenessMinContinuity) {
        return const FaceValidationResult(
          isValid: false,
          message: 'Unable to confirm the same live face. Keep centered and retry.',
        );
      }

      if (continuity > _suspiciouslyStaticContinuity &&
          poseDelta < _minPoseDeltaForStaticGuard) {
        return const FaceValidationResult(
          isValid: false,
          message: 'Possible static photo detected. Move naturally and try again.',
        );
      }

      return const FaceValidationResult(
        isValid: true,
        message: 'Liveness check passed.',
      );
    } catch (e) {
      return FaceValidationResult(
        isValid: false,
        message:
            'Liveness check could not be completed. Keep your face centered and try again.',
      );
    }
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

}
