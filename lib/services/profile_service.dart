import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import '../models/profile_model.dart';

class ProfileService {
  static String get _baseUrl => ApiConfig.baseUrl;

  Future<ProfileUser?> fetchProfile(String token) async {
    final url = Uri.parse('$_baseUrl/employees/profile');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Profile request timed out'),
          );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        // /employees/profile returns { success, data: {...} }
        final userJson =
            (decoded['data'] ?? decoded['user']) as Map<String, dynamic>?;
        if (userJson == null) return null;
        return ProfileUser.fromJson(userJson);
      } else {
        print('Profile Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Profile Error: $e');
      return null;
    }
  }

  /// Change employee password — PUT /api/employees/change-password
  Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$_baseUrl/employees/change-password');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': decoded['success'] ?? false,
          'message': decoded['message'] ?? 'Unexpected response',
        };
      } catch (_) {
        return {
          'success': false,
          'message': 'Server error (${response.statusCode})',
        };
      }
    } catch (e) {
      print('changePassword Error: $e');
      return {
        'success': false,
        'message': 'Connection failed. Please check your internet.',
      };
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String userId,
    required Map<String, dynamic> payload,
  }) async {
    final url = Uri.parse('$_baseUrl/users/profile');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          // /employees/profile returns { success, message, data: {...} }
          final userJson =
              (decoded['data'] ?? decoded['user']) as Map<String, dynamic>?;
          if (userJson == null) {
            return {
              'success': false,
              'message': 'Invalid response from server',
            };
          }
          return {'success': true, 'user': ProfileUser.fromJson(userJson)};
        } catch (e) {
          print('Profile Parse Error: ${response.body}');
          return {
            'success': false,
            'message': 'Failed to parse server response',
          };
        }
      } else {
        String message = 'Failed to update profile';
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          message = decoded['message'] ?? message;
        } catch (e) {
          message = 'Server error (${response.statusCode})';
        }
        print('Profile Update Error: ${response.body}');
        return {'success': false, 'message': message};
      }
    } catch (e) {
      print('Profile Update Error: $e');
      return {
        'success': false,
        'message': 'Connection failed. Please check your internet.',
      };
    }
  }

  Future<Map<String, dynamic>> uploadProfilePhoto({
    required String token,
    required String imagePath,
  }) async {
    final url = Uri.parse('$_baseUrl/users/profile');

    try {
      var request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = 'Bearer $token';

      // Add the image file
      var file = await http.MultipartFile.fromPath(
        'profilePhoto',
        imagePath,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(file);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          // /employees/profile returns { success, message, data: {...} }
          final userJson =
              (decoded['data'] ?? decoded['user']) as Map<String, dynamic>?;
          if (userJson == null) {
            return {
              'success': false,
              'message': 'Invalid response from server',
            };
          }
          return {
            'success': true,
            'user': ProfileUser.fromJson(userJson),
            'message': 'Profile photo updated successfully',
          };
        } catch (e) {
          print('Photo Upload Parse Error: ${response.body}');
          return {
            'success': false,
            'message': 'Failed to parse server response',
          };
        }
      } else {
        String message = 'Failed to upload photo';
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          message = decoded['message'] ?? message;
        } catch (e) {
          message = 'Server error (${response.statusCode})';
        }
        print('Photo Upload Error: ${response.body}');
        return {'success': false, 'message': message};
      }
    } catch (e) {
      print('Photo Upload Error: $e');
      return {
        'success': false,
        'message': 'Connection failed. Please check your internet.',
      };
    }
  }
}
