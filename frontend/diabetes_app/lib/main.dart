import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/add_diet_screen.dart';
import 'screens/meal_plan_screen.dart';
import 'screens/recommendation_screen.dart'; // Make sure this import points to your actual file

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diet Recommendations App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/addDiet': (context) => AddDietScreen(),
        '/recommendation': (context) => RecommendationScreen(),
        '/mealPlan': (context) => MealPlanScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (context) => NotFoundPage());
      },
    );
  }
}

class NotFoundPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Not Found")),
      body: Center(child: Text("The page you are looking for doesn't exist.")),
    );
  }
}





// import 'package:flutter/material.dart';
// import 'screens/login_screen.dart';
// import 'screens/meal_plan_screen.dart';
// 
// void main() {
//   runApp(MyApp());
// }
// 
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       initialRoute: '/',
//       routes: {
//         '/': (context) => LoginScreen(),
//         '/addDiet': (context) => AddDietScreen(),
//   		'/recommendation': (context) => RecommendationScreen(),
//         '/mealPlan': (context) => MealPlanScreen(),
//       },
//     );
//   }
// }
