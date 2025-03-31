import 'package:flutter/material.dart';

class RecommendationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recommendation'),
      ),
      body: Center(
        child: Text('Your personalized diet recommendation will appear here.'),
      ),
    );
  }
}
