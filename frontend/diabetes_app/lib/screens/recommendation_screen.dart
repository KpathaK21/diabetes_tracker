// lib/screens/recommendation_screen.dart

import 'package:flutter/material.dart';
import 'package:diabetes_app/services/auth_service.dart';

class RecommendationScreen extends StatelessWidget {
  final String recommendation;

  const RecommendationScreen({Key? key, required this.recommendation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Diet Recommendation"),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recommendation,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/history');
                },
                icon: Icon(Icons.history),
                label: Text("View History"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
