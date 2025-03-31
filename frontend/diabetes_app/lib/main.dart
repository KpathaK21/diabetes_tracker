import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'meal_plan_screen.dart';
import 'auth_service.dart'; // Import the AuthService

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => FutureBuilder<String?>(
          future: AuthService().getToken(), // Get the saved token
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(body: Center(child: CircularProgressIndicator()));
            } else if (snapshot.hasData && snapshot.data != null) {
              // If token is found, navigate directly to meal plan screen
              return MealPlanScreen();
            } else {
              // If no token, show the login screen
              return LoginScreen();
            }
          },
        ),
        '/mealPlan': (context) => MealPlanScreen(),
      },
    );
  }
}
