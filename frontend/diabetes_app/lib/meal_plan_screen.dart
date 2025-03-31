import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MealPlanScreen extends StatefulWidget {
  @override
  _MealPlanScreenState createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  String? recommendation;
  bool isLoading = true; // Track loading state
  bool hasError = false; // Flag to handle errors

  // Fetch data from the backend
  Future<void> fetchRecommendation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');  // Get the token from storage

    print("Using token: $token"); // Check what token is being used

    if (token != null) {
      try {
        final response = await http.post(
          Uri.parse('http://localhost:8080/diet/recommend'),
          headers: {
            'Authorization': 'Bearer $token',  // Use the stored token
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          // Parse the response data
          var data = json.decode(response.body);
          setState(() {
            recommendation = data['recommendation'];
            isLoading = false; // Set loading state to false
          });
        } else {
          setState(() {
            hasError = true; // Mark error flag
            isLoading = false;
          });
        }
      } catch (error) {
        setState(() {
          hasError = true; // Mark error flag
          isLoading = false;
        });
      }
    } else {
      setState(() {
        hasError = true; // Token not found error
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRecommendation();  // Fetch recommendation when the screen loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Today's Meal Plan")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator()) // Show loading indicator
            : hasError
                ? Center(child: Text('Failed to load recommendation. Please try again.')) // Show error message
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Meal Plan for Today',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      Text(
                        recommendation!,
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
      ),
    );
  }
}

