// lib/screens/recommendation_screen.dart

import 'package:flutter/material.dart';
import 'package:diabetes_app/services/auth_service.dart';

class RecommendationScreen extends StatelessWidget {
  final String recommendation;

  const RecommendationScreen({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Diet Recommendation"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/history');
                },
                icon: const Icon(Icons.history),
                label: const Text("View History"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
