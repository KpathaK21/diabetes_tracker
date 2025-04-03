import 'package:flutter/material.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
	// Login function
	Future<bool> loginUser(String email, String password) async {
	  final response = await http.post(
	    Uri.parse('http://localhost:8080/login'),
	    headers: {'Content-Type': 'application/json'},
	    body: json.encode({'email': email, 'password': password}),
	  );

	  if (response.statusCode == 200) {
	    var data = json.decode(response.body);
	    String token = data['token'];
	    SharedPreferences prefs = await SharedPreferences.getInstance();
	    await prefs.setString('jwt_token', token);
	    print("Token saved: $token");
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
	}

	 // Save glucose values after signup
	Future<bool> saveGlucoseData(double fastingGlucose, double postprandialGlucose) async {
	  final response = await http.post(
	    Uri.parse('http://localhost:8080/saveGlucoseData'),
	    headers: {'Content-Type': 'application/json'},
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
	}

	// Signup function
	Future<Map<String, dynamic>> signupUser(String email, String password, String fullName, String dob, String gender) async {
	  try {
	    final response = await http.post(
	      Uri.parse('http://localhost:8080/signup'),
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
	      Uri.parse('http://localhost:8080/verify'),
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
	  SharedPreferences prefs = await SharedPreferences.getInstance();
	  return prefs.getString('jwt_token');
	}

	// ✅ Logout method that accepts context
	Future<void> logout(BuildContext context) async {
	  final prefs = await SharedPreferences.getInstance();
	  await prefs.remove('jwt_token');
	  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
	}
	}

