import 'dart:convert';
import 'package:dio/dio.dart';

class PanchangService {
  static const String _clientId = '9fec1998-a2c6-4dff-ab53-83246c11e84f';
  static const String _clientSecret = 'w8myHMxsJdJcKMIGl8psghlPxvVQQdRhERpGZAtl';
  static const String _baseUrl = 'https://api.prokerala.com';
  static final Dio _dio = Dio();

  static Future<String?> _getAccessToken() async {
    try {
      final response = await _dio.post(
        '$_baseUrl/token',
        data: {
          'grant_type': 'client_credentials',
          'client_id': _clientId,
          'client_secret': _clientSecret,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      if (response.statusCode == 200) {
        return response.data['access_token'];
      }
    } catch (e) {
      print('Token error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getTodayPanchang() async {
    try {
      final token = await _getAccessToken();
      if (token == null) return null;

      final now = DateTime.now();
      final date =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T06:00:00+05:30';

      final response = await _dio.get(
        '$_baseUrl/v2/astrology/panchang',
        queryParameters: {
          'ayanamsa': 1,
          'coordinates': '23.1765,75.7885',
          'datetime': date,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print('Panchang error: $e');
    }
    return null;
  }
}
