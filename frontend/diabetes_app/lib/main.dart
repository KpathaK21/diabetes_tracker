import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uni_links/uni_links.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/glucose_setup_screen.dart';
import 'screens/add_diet_screen.dart';
import 'screens/meal_plan_screen.dart';
import 'screens/recommendation_screen.dart';
import 'screens/history_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/food_image_screen.dart';
import 'services/auth_service.dart';

bool _initialUriIsHandled = false;

// Global key for navigator to use in deep linking
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Uri? _initialUri;
  Uri? _latestUri;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
    _handleInitialUri();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // Handle incoming links - deep linking
  void _handleIncomingLinks() {
    // Skip for web platform as link streams are not supported
    if (kIsWeb) {
      print('Link stream listening is not supported on web platform');
      return;
    }
    
    // It will handle app links while the app is already started - only for non-web platforms
    _sub = uriLinkStream.listen((Uri? uri) {
      print('got uri: $uri');
      setState(() {
        _latestUri = uri;
        if (uri != null && uri.path == '/verify') {
          // Extract token from the URI
          String? token = uri.queryParameters['token'];
          if (token != null && token.isNotEmpty) {
            // Navigate to verification screen with the token
            navigatorKey.currentState?.pushNamed(
              '/email_verification',
              arguments: {'token': token},
            );
          }
        }
      });
    }, onError: (Object err) {
      print('Error occurred: $err');
    });
  }

  // Handle the initial URI - deep linking
  Future<void> _handleInitialUri() async {
    if (!_initialUriIsHandled) {
      _initialUriIsHandled = true;
      try {
        // getInitialUri still works on web, but returns null if no initial link
        final uri = await getInitialUri();
        print('Initial URI: $uri');
        if (uri != null && uri.path == '/verify') {
          // Extract token from the URI
          String? token = uri.queryParameters['token'];
          if (token != null && token.isNotEmpty) {
            // Set the initial route to verification with the token
            _initialUri = uri;
            // We'll handle this in the onGenerateRoute
          }
        }
      } on PlatformException {
        print('Failed to get initial URI');
      } on FormatException {
        print('Malformed initial URI');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Diet Recommendations App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/signup',
      onGenerateRoute: (settings) {
        // Check if we have an initial URI with a verification token
        if (_initialUri != null && 
            _initialUri!.path == '/verify' && 
            settings.name == '/signup') {
          String? token = _initialUri!.queryParameters['token'];
          if (token != null && token.isNotEmpty) {
            // Override the initial route to go to verification
            return MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(
                initialToken: token,
              ),
            );
          }
        }

        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => LoginScreen());
          case '/signup':
            return MaterialPageRoute(builder: (_) => SignupScreen());
          case '/glucose_setup_screen':
            return MaterialPageRoute(builder: (_) => GlucoseSetupScreen());  
          case '/addDiet':
            return MaterialPageRoute(builder: (_) => AddDietScreen());
          case '/mealPlan':
            return MaterialPageRoute(builder: (_) => MealPlanScreen());
          case '/history':
            return MaterialPageRoute(builder: (_) => HistoryScreen());
          case '/foodImage':
            return MaterialPageRoute(builder: (_) => FoodImageScreen());
          case '/email_verification':
            final args = settings.arguments;
            String email = '';
            String? token;
            
            if (args is Map<String, dynamic>) {
              email = args['email'] as String? ?? '';
              token = args['token'] as String?;
            } else if (args is String) {
              email = args;
            }
            
            return MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(
                email: email,
                initialToken: token,
              ),
            );
          case '/recommendation':
            final recommendation = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => RecommendationScreen(recommendation: recommendation),
            );
          default:
            return MaterialPageRoute(builder: (_) => NotFoundPage());
        }
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
