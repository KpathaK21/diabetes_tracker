import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DietService {
  // Function to add a diet log
  Future<void> addDietLog(String foodDescription, int calories, String nutrients) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null) {
      print("No token found");
      return;
    }

    final response = await http.post(
      Uri.parse('http://localhost:8080/diet'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'foodDescription': foodDescription,
        'calories': calories,
        'nutrients': nutrients,
      }),
    );

    if (response.statusCode == 200) {
      print("Diet log added successfully");
    } else {
      print("Failed to add diet log: ${response.body}");
    }
  }
}
