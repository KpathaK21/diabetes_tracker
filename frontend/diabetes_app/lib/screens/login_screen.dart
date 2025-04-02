// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:diabetes_app/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  void _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      bool success = await AuthService().loginUser(_email, _password);

      setState(() => _isLoading = false);

      if (success) {
        Navigator.pushReplacementNamed(context, '/addDiet');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed. Please check your credentials.")),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      String errorMessage = e.toString();
      if (errorMessage.contains("verify your email")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please verify your email address before logging in."),
            action: SnackBarAction(
              label: 'Verify',
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/email_verification', arguments: _email);
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed: $errorMessage")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                onSaved: (value) => _email = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your email' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                onSaved: (value) => _password = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your password' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitLogin,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
