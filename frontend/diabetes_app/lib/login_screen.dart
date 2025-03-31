import 'package:flutter/material.dart';
import 'auth_service.dart'; // Import AuthService

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false; // To show loading indicator during login

  // Function to handle user login
  void loginUser(BuildContext context) async {
    String email = emailController.text; // Get email from user input
    String password = passwordController.text; // Get password from user input

    // Validate email and password
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter both email and password')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Call the login function from AuthService
    await authService.loginUser(email, password);

    setState(() {
      isLoading = false;
    });

    // After successful login, navigate to another screen or display success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login successful, token saved.')),
    );

    // Navigate to the meal plan screen
    Navigator.pushReplacementNamed(context, '/mealPlan');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                border: OutlineInputBorder(),
              ),
              obscureText: true, // To hide the password
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading
                  ? null // Disable the button while loading
                  : () => loginUser(context),
              child: isLoading
                  ? CircularProgressIndicator()
                  : Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
