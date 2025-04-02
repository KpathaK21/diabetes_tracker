// lib/services/diet_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DietService {
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

  // 🆕 Get diet + glucose history from the backend
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
}
