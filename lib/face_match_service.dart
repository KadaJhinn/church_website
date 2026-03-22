import 'dart:convert';
import 'package:http/http.dart' as http;

class FaceMatchService {
  static const String _apiKey = '7tStA3D_kKf5r2QS5F5IphkGQUlsO1Am';
  static const String _apiSecret = 'P9RMbJfTjj9gwC94juQ46MwgstV8VGMG';
  static const String _apiUrl =
      'https://api-us.faceplusplus.com/facepp/v3/compare';

  static Future<double> compareFaces({
    required String webcamBase64,
    required String storedPhotoUrl,
  }) async {
    try {
      final storedResponse = await http.get(Uri.parse(storedPhotoUrl));
      if (storedResponse.statusCode != 200) {
        throw Exception('Could not fetch stored member photo');
      }
      final storedBase64 = base64Encode(storedResponse.bodyBytes);

      final response = await http.post(
        Uri.parse(_apiUrl),
        body: {
          'api_key': _apiKey,
          'api_secret': _apiSecret,
          'image_base64_1': webcamBase64,
          'image_base64_2': storedBase64,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['confidence'] == null) {
          throw Exception('No face detected in one or both photos');
        }
        return (data['confidence'] as num).toDouble();
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Face++ error: ${error['error_message']}');
      }
    } catch (e) {
      throw Exception('Face match failed: $e');
    }
  }

  static bool isSamePerson(double confidence) => confidence >= 80.0;
}