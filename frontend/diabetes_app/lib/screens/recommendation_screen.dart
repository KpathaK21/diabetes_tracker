// lib/screens/recommendation_screen.dart

import 'package:flutter/material.dart';
import 'package:diabetes_app/services/auth_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
            Expanded(
              child: Markdown(
                data: recommendation,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 16),
                  h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  h2: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  h3: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  strong: const TextStyle(fontWeight: FontWeight.bold),
                  em: const TextStyle(fontStyle: FontStyle.italic),
                  listBullet: const TextStyle(fontSize: 16),
                ),
                shrinkWrap: true,
              ),
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
