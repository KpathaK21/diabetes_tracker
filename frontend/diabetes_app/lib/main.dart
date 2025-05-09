import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:app_links/app_links.dart';
import 'dart:io';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/glucose_setup_screen.dart';
import 'screens/add_diet_screen.dart';
import 'screens/meal_plan_screen.dart';
import 'screens/recommendation_screen.dart';
import 'screens/history_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/food_image_screen.dart';

bool _initialUriIsHandled = false;

// Global key for navigator to use in deep linking
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Allow self-signed certificates in development mode
  HttpOverrides.global = DevHttpOverrides();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

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
    final appLinks = AppLinks();
    
    // Subscribe to app links
    _sub = appLinks.uriLinkStream.listen((Uri? uri) {
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
        // Get the initial app link
        final appLinks = AppLinks();
        final uri = await appLinks.getInitialAppLink();
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
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/signup':
            return MaterialPageRoute(builder: (_) => const SignupScreen());
          case '/glucose_setup_screen':
            return MaterialPageRoute(builder: (_) => const GlucoseSetupScreen());  
          case '/addDiet':
            return MaterialPageRoute(builder: (_) => const AddDietScreen());
          case '/mealPlan':
            return MaterialPageRoute(builder: (_) => const MealPlanScreen());
          case '/history':
            return MaterialPageRoute(builder: (_) => const HistoryScreen());
          case '/foodImage':
            return MaterialPageRoute(builder: (_) => const FoodImageScreen());
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
            return MaterialPageRoute(builder: (_) => const NotFoundPage());
        }
      },
    );
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Not Found")),
      body: const Center(child: Text("The page you are looking for doesn't exist.")),
    );
  }
}
