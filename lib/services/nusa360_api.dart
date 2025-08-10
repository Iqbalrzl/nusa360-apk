import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = "http://103.63.25.133:8080";

  // === LOGIN ===
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();

      final token = data['token'];
      if (token != null) await prefs.setString('token', token);

      if (data['user'] != null) {
        await prefs.setString('user', jsonEncode(data['user']));
      } else {
        final meUrl = Uri.parse('$baseUrl/profile/me');
        final meResponse = await http.get(
          meUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (meResponse.statusCode == 200) {
          await prefs.setString('user', meResponse.body);
        }
      }

      print("Login successful. Token & user cached.");
      return data;
    }

    print('Login failed: ${response.statusCode} ${response.body}');
    return null;
  }

  // === REGISTER ===
  Future<bool> registerUser(
    String username,
    String email,
    String password,
  ) async {
    if (password.length < 4) {
      print('Password harus minimal 4 karakter');
      return false;
    }

    final url = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    return (response.statusCode == 200 || response.statusCode == 201);
  }

  // === GET ME ===
  Future<Map<String, dynamic>?> getMe() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    final url = Uri.parse('$baseUrl/profile/me');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return (response.statusCode == 200) ? jsonDecode(response.body) : null;
  }

  // === UPDATE PROFILE ===
  Future<bool> updateProfile({String? username, String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return false;

    final cachedUserJson = prefs.getString('user');
    if (cachedUserJson == null) return false;

    final cachedUser = jsonDecode(cachedUserJson);
    final Map<String, dynamic> data = {};

    if (username != null && username != cachedUser['username'])
      data['username'] = username;
    if (email != null && email != cachedUser['email']) data['email'] = email;
    if (data.isEmpty) return false;

    try {
      final url = Uri.parse('$baseUrl/profile/me');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        final meUrl = Uri.parse('$baseUrl/profile/me');
        final meResponse = await http.get(
          meUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (meResponse.statusCode == 200) {
          await prefs.setString('user', meResponse.body);
        }
        return true;
      }
    } catch (e) {
      print('Error during profile update: $e');
    }
    return false;
  }

  // === GET CACHED USER ===
  Future<Map<String, dynamic>?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      try {
        return jsonDecode(userJson);
      } catch (e) {
        print('Error decoding cached user: $e');
      }
    }
    return null;
  }

  // === LOGOUT ===
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    print("User logged out. Cache cleared.");
  }

  // === UPLOAD AVATAR ===
  Future<String?> uploadAvatar(XFile image) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    final url = Uri.parse('$baseUrl/profile/avatar');
    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';

    final bytes = await image.readAsBytes();
    final fileName = image.name;
    final mimeType = lookupMimeType(fileName) ?? 'image/png';

    try {
      request.files.add(
        await http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['avatarUrl'];
      }
    } catch (e) {
      print('Error during avatar upload: $e');
    }
    return null;
  }

  // === GET AVATAR URL ===
  Future<String?> getAvatarUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    final url = Uri.parse('$baseUrl/profile/avatar');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['avatarUrl'];
    }
    return null;
  }

  // === ASK AI ===
  Future<String?> askAi(String query, String context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    final url = Uri.parse('$baseUrl/askAi');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'query': query, 'context': context}),
    );

    return (response.statusCode == 200) ? response.body : null;
  }
}
