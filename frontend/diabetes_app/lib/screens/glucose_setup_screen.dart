import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GlucoseSetupScreen extends StatefulWidget {
  const GlucoseSetupScreen({super.key});

  @override
  _GlucoseSetupScreenState createState() => _GlucoseSetupScreenState();
}

class _GlucoseSetupScreenState extends State<GlucoseSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  double _fastingGlucose = 0;
  double _postprandialGlucose = 0;
  final bool _isLoading = false;

  void _submitGlucoseLevels() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    final response = await http.post(
      Uri.parse('http://localhost:8080/set_glucose_levels'), // Ensure this is the correct endpoint
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'fasting_glucose': _fastingGlucose,
        'postprandial_glucose': _postprandialGlucose,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pushReplacementNamed(context, '/addDiet'); // Navigate after successful saving
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save glucose levels')));
      print("Error response: ${response.body}"); // Log the response for debugging
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Glucose Levels")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Fasting Glucose (mg/dL)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter fasting glucose' : null,
                onSaved: (value) => _fastingGlucose = double.parse(value!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Postprandial Glucose (mg/dL)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter postprandial glucose' : null,
                onSaved: (value) => _postprandialGlucose = double.parse(value!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitGlucoseLevels,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
