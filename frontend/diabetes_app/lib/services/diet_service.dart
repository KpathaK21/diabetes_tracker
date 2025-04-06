// lib/services/diet_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class DietService {
  final ImagePicker _picker = ImagePicker();

  Future<String> addDietLogWithGlucose(
      String foodDescription,
      int calories,
      String nutrients,
      double glucoseLevel,
      String mealTag,
      String mealType,
      String notes) async {
        
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null) {
      print("No token found");
      return "No token";
    }

    final response = await http.post(
      Uri.parse('http://localhost:8080/submit_and_recommend'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "glucose": {
          "level": glucoseLevel,
          "meal_tag": mealTag,
          "meal_type": mealType,
          "notes": notes
        },
        "diet": {
          "food_description": foodDescription,
          "calories": calories,
          "nutrients": nutrients
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['recommendation'] ?? "No recommendation found";
    } else {
      print("Failed to add diet and glucose log: ${response.body}");
      return "Failed: ${response.body}";
    }
  }

  // Get diet + glucose history from the backend
  Future<Map<String, dynamic>?> fetchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null) {
      print("No token found");
      return null;
    }

    final response = await http.get(
      Uri.parse('http://localhost:8080/history'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print("Failed to fetch history: ${response.body}");
      return null;
    }
  }

  // Pick an image from gallery or camera
  Future<File?> pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // Convert image file to base64
  Future<String> imageToBase64(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }
  
  // Convert Uint8List to base64 (for web)
  Future<String> bytesToBase64(Uint8List bytes) async {
    return base64Encode(bytes);
  }

  // Classify food image
  Future<Map<String, dynamic>?> classifyFoodImage(File imageFile) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null) {
      print("No token found");
      return null;
    }

    // Convert image to base64
    String base64Image = await imageToBase64(imageFile);

    final response = await http.post(
      Uri.parse('http://localhost:8080/classify_food_image'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "image": base64Image,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print("Failed to classify image: ${response.body}");
      return null;
    }
  }
  
  // Classify food image using base64 string
  Future<Map<String, dynamic>?> classifyFoodImageBase64(String base64Image) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null) {
      print("No token found");
      return null;
    }

    final response = await http.post(
      Uri.parse('http://localhost:8080/classify_food_image'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "image": base64Image,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print("Failed to classify image: ${response.body}");
      return null;
    }
  }

  // Submit image and get recommendation
  Future<String> submitImageAndRecommend(
      File imageFile,
      double glucoseLevel,
      String mealTag,
      String mealType,
      String notes) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null) {
      print("No token found");
      return "No token";
    }

    // Convert image to base64
    String base64Image = await imageToBase64(imageFile);

    final response = await http.post(
      Uri.parse('http://localhost:8080/submit_image_and_recommend'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "image": base64Image,
        "glucose": {
          "level": glucoseLevel,
          "meal_tag": mealTag,
          "meal_type": mealType,
          "notes": notes
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['recommendation'] ?? "No recommendation found";
    } else {
      print("Failed to submit image and get recommendation: ${response.body}");
      return "Failed: ${response.body}";
    }
  }
  
  // Submit image as base64 and get recommendation
  Future<String> submitImageAndRecommendBase64(
      String base64Image,
      double glucoseLevel,
      String mealTag,
      String mealType,
      String notes) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null) {
      print("No token found");
      return "No token";
    }

    final response = await http.post(
      Uri.parse('http://localhost:8080/submit_image_and_recommend'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "image": base64Image,
        "glucose": {
          "level": glucoseLevel,
          "meal_tag": mealTag,
          "meal_type": mealType,
          "notes": notes
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['recommendation'] ?? "No recommendation found";
    } else {
      print("Failed to submit image and get recommendation: ${response.body}");
      return "Failed: ${response.body}";
    }
  }
}
