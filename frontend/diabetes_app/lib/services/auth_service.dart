import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Create an HTTP client that accepts self-signed certificates (for development only)
class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

// Secure storage for tokens
class SecureTokenStorage {
  // Use FlutterSecureStorage for mobile platforms
  final _secureStorage = FlutterSecureStorage();
  
  // Check if we're on macOS
  bool get _isMacOS => !kIsWeb && Platform.isMacOS;
  
  // Save token - use SharedPreferences for macOS, secure storage for others
  Future<void> saveToken(String token) async {
    if (_isMacOS) {
      // Use SharedPreferences for macOS
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
    } else {
      // Use secure storage for other platforms
      await _secureStorage.write(key: 'jwt_token', value: token);
    }
  }
  
  // Get token
  Future<String?> getToken() async {
    if (_isMacOS) {
      // Use SharedPreferences for macOS
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('jwt_token');
    } else {
      // Use secure storage for other platforms
      return await _secureStorage.read(key: 'jwt_token');
    }
  }
  
  // Delete token
  Future<void> deleteToken() async {
    if (_isMacOS) {
      // Use SharedPreferences for macOS
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
    } else {
      // Use secure storage for other platforms
      await _secureStorage.delete(key: 'jwt_token');
    }
  }
  
  // For refresh token
  Future<void> saveRefreshToken(String token) async {
    if (_isMacOS) {
      // Use SharedPreferences for macOS
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('refresh_token', token);
    } else {
      // Use secure storage for other platforms
      await _secureStorage.write(key: 'refresh_token', value: token);
    }
  }
  
  Future<String?> getRefreshToken() async {
    if (_isMacOS) {
      // Use SharedPreferences for macOS
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('refresh_token');
    } else {
      // Use secure storage for other platforms
      return await _secureStorage.read(key: 'refresh_token');
    }
  }
  
  Future<void> deleteRefreshToken() async {
    if (_isMacOS) {
      // Use SharedPreferences for macOS
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('refresh_token');
    } else {
      // Use secure storage for other platforms
      await _secureStorage.delete(key: 'refresh_token');
    }
  }
  
  // Delete all tokens
  Future<void> clearTokens() async {
    if (_isMacOS) {
      // Use SharedPreferences for macOS
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      await prefs.remove('refresh_token');
    } else {
      // Use secure storage for other platforms
      await _secureStorage.deleteAll();
    }
  }
}

class AuthService {
  final SecureTokenStorage _tokenStorage = SecureTokenStorage();
  final String _baseUrl = 'http://localhost:8080'; // Use HTTP for development
  
  // Create a custom HTTP client that accepts self-signed certificates
  http.Client _createClient() {
    HttpClient httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    
    return http.Client();
  }

  // Login function
  Future<bool> loginUser(String email, String password) async {
    try {
      // For development, use http instead of https to avoid certificate issues
      final response = await http.post(
        Uri.parse('http://localhost:8080/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        String token = data['token'];
        String? refreshToken = data['refresh_token']; // Handle refresh token if available
        
        // Save tokens securely
        await _tokenStorage.saveToken(token);
        if (refreshToken != null) {
          await _tokenStorage.saveRefreshToken(refreshToken);
        }
        
        print("Token saved securely");
        return true;
      } else {
        print("Login failed: ${response.body}");
        var data = json.decode(response.body);
        String errorMessage = data['error'] ?? 'Login failed';
        
        // Check if the error is related to email verification
        if (response.statusCode == 401 && errorMessage.contains('verify your email')) {
          throw Exception(errorMessage);
        }
        
        return false;
      }
    } catch (e) {
      print("Exception during login: $e");
      if (e is Exception && e.toString().contains('verify your email')) {
        rethrow;
      }
      return false;
    }
  }

  // Save glucose values after signup
  Future<bool> saveGlucoseData(double fastingGlucose, double postprandialGlucose) async {
    try {
      // Get token for authorization
      final token = await _tokenStorage.getToken();
      if (token == null) {
        print("No auth token available");
        return false;
      }
      
      // Check if token needs refresh
      if (await _isTokenExpired()) {
        await _refreshTokenIfNeeded();
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/saveGlucoseData'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode({
          'fasting_glucose': fastingGlucose,
          'postprandial_glucose': postprandialGlucose,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Failed to save glucose data: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception during glucose data save: $e");
      return false;
    }
  }

  // Signup function
  Future<Map<String, dynamic>> signupUser(String email, String password, String fullName, String dob, String gender) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'full_name': fullName,
          'dob': dob,
          'gender': gender
        }),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        // With email verification, we no longer get a token immediately
        // Instead, we get a message and verification status
        print("Signup successful: ${response.body}");
        return {
          'success': true,
          'message': data['message'],
          'verified': data['verified'] ?? false
        };
      } else {
        print("Signup failed: ${response.body}");
        var data = json.decode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? 'Signup failed. Please try again.'
        };
      }
    } catch (e) {
      print("Exception during signup: $e");
      return {
        'success': false,
        'message': 'Connection error. Please check your internet connection and try again.'
      };
    }
  }
  
  // Verify email function with verification code
  Future<Map<String, dynamic>> verifyEmail(String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'code': code}),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print("Email verification successful: ${response.body}");
        return {
          'success': true,
          'message': data['message'] ?? 'Email verified successfully'
        };
      } else {
        print("Email verification failed: ${response.body}");
        var data = json.decode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? 'Email verification failed. Please try again.'
        };
      }
    } catch (e) {
      print("Exception during email verification: $e");
      return {
        'success': false,
        'message': 'Connection error. Please check your internet connection and try again.'
      };
    }
  }

  // Retrieve stored token
  Future<String?> getToken() async {
    return await _tokenStorage.getToken();
  }
  
  // Check if token is expired
  Future<bool> _isTokenExpired() async {
    final token = await _tokenStorage.getToken();
    if (token == null) return true;
    
    try {
      // Decode JWT
      final parts = token.split('.');
      if (parts.length != 3) return true;
      
      // Decode payload
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> jwt = json.decode(decoded);
      
      // Check expiration
      final expiry = DateTime.fromMillisecondsSinceEpoch((jwt['exp'] as int) * 1000);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      print("Error checking token expiration: $e");
      return true; // If we can't decode the token, assume it's expired
    }
  }
  
  // Refresh token if needed
  Future<bool> _refreshTokenIfNeeded() async {
    if (await _isTokenExpired()) {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) return false;
      
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'refresh_token': refreshToken}),
        );
        
        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          String newToken = data['token'];
          await _tokenStorage.saveToken(newToken);
          return true;
        } else {
          // If refresh fails, clear tokens and require re-login
          await _tokenStorage.clearTokens();
          return false;
        }
      } catch (e) {
        print("Error refreshing token: $e");
        return false;
      }
    }
    return true; // Token is still valid
  }

  // Logout method that accepts context
  Future<void> logout(BuildContext context) async {
    await _tokenStorage.clearTokens();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }
}
