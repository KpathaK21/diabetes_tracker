import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:diabetes_app/services/auth_service.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null) {
      setState(() {
        isLoading = false;
        history = [];
      });
      return;
    }

    final response = await http.get(
      Uri.parse('http://localhost:8080/history'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        history = data['history'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
        history = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Diet + Glucose History"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () {
              AuthService().logout(context);
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : history.isEmpty
              ? Center(child: Text("No logs available"))
              : ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("📅 ${entry['timestamp']}", style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text("🍽 Food: ${entry['food_description']}"),
                            Text("🔥 Calories: ${entry['calories']}"),
                            Text("🔬 Nutrients: ${entry['nutrients']}"),
                            Text("💉 Glucose: ${entry['glucose_level']} mg/dL"),
                            Text("🕒 Meal Tag: ${entry['meal_tag']}"),
                            Text("📌 Meal Type: ${entry['meal_type']}"),
                            Text("📝 Notes: ${entry['notes']}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
