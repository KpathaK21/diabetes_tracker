// lib/screens/recommendation_screen.dart

import 'package:flutter/material.dart';

class RecommendationScreen extends StatelessWidget {
  final String recommendation;

  const RecommendationScreen({Key? key, required this.recommendation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Diet Recommendation"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(recommendation),
      ),
    );
  }
}
