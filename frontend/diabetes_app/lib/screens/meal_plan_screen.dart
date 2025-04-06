import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
// Adjust import based on your structure

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  _MealPlanScreenState createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  String? recommendation;
  bool isLoading = false;

  Future<void> fetchRecommendation() async {
    setState(() { isLoading = true; });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token != null) {
      final response = await http.post(
        Uri.parse('http://localhost:8080/diet/recommend'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          recommendation = data['recommendation'];
          isLoading = false;
        });
      } else {
        setState(() {
          recommendation = "Failed to load recommendation.";
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Meal Plan")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (recommendation != null)
                  Text(
                    recommendation!,
                    style: const TextStyle(fontSize: 18),
                  ),
                ElevatedButton(
                  onPressed: fetchRecommendation,
                  child: const Text('Get Recommendation'),
                ),
              ],
            ),
      ),
    );
  }
}
