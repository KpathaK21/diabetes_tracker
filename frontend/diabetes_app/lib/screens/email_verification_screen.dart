// lib/screens/email_verification_screen.dart

import 'package:flutter/material.dart';
import 'package:diabetes_app/services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String? initialToken;
  final String? email;

  const EmailVerificationScreen({super.key, this.initialToken, this.email});

  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tokenController = TextEditingController();
  bool _isLoading = false;
  String _email = '';

  @override
  void initState() {
    super.initState();
    // If an initial token was provided, set it in the controller
    if (widget.initialToken != null && widget.initialToken!.isNotEmpty) {
      _tokenController.text = widget.initialToken!;
      // Auto-verify if token is provided
      Future.delayed(const Duration(milliseconds: 500), () {
        _submitVerification();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the email from the route arguments or widget parameter
    if (widget.email != null && widget.email!.isNotEmpty) {
      _email = widget.email!;
    } else {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is String) {
        _email = args;
      } else if (args != null && args is Map<String, dynamic>) {
        _email = args['email'] as String? ?? '';
        String? token = args['token'] as String?;
        if (token != null && token.isNotEmpty && _tokenController.text.isEmpty) {
          _tokenController.text = token;
          // Auto-verify if token is provided
          Future.delayed(const Duration(milliseconds: 500), () {
            _submitVerification();
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _submitVerification() async {
    if (_tokenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a verification token')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService().verifyEmail(_tokenController.text);

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        
        // Navigate to login screen after successful verification
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred during verification. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Email Verification")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 64,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Verify Your Email",
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "We've sent a verification code to $_email. Please check your email and enter the code below to verify your account.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Didn't receive the email? Check your spam folder or request a new code.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextField(
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      labelText: 'Verification Code',
                      border: OutlineInputBorder(),
                      helperText: 'Enter the 6-digit code from your verification email',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(
                      fontSize: 20,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitVerification,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Verify Email'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
              child: const Text("Back to Login"),
            ),
          ],
        ),
      ),
    );
  }
}