// File: lib/screens/add_diet_screen.dart
import 'package:flutter/material.dart';
import 'package:diabetes_app/services/diet_service.dart'; // Correct this import as per your project structure

class AddDietScreen extends StatefulWidget {
  @override
  _AddDietScreenState createState() => _AddDietScreenState();
}

class _AddDietScreenState extends State<AddDietScreen> {
  final _formKey = GlobalKey<FormState>();
  final _focusNodeCalories = FocusNode();
  final _focusNodeNutrients = FocusNode();
  String _foodDescription = '';
  int _calories = 0;
  String _nutrients = '';
  bool _isLoading = false;

  void _submitDietLog() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      DietService().addDietLog(_foodDescription, _calories, _nutrients).then((_) {
        Navigator.pushNamed(context, '/recommendation'); // Assuming you have a route set up
      }).catchError((error) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to add diet log: $error")));
      }).whenComplete(() => setState(() => _isLoading = false));
    }
  }

  @override
  void dispose() {
    _focusNodeCalories.dispose();
    _focusNodeNutrients.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Diet Log")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Food Description'),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_focusNodeCalories);
                },
                onSaved: (value) => _foodDescription = value!,
                validator: (value) => value!.isEmpty ? 'Please enter some text' : null,
              ),
              TextFormField(
                focusNode: _focusNodeCalories,
                decoration: InputDecoration(labelText: 'Calories'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_focusNodeNutrients);
                },
                onSaved: (value) => _calories = int.parse(value!),
                validator: (value) => value!.isEmpty ? 'Please enter calories' : null,
              ),
              TextFormField(
                focusNode: _focusNodeNutrients,
                decoration: InputDecoration(labelText: 'Nutrients'),
                onSaved: (value) => _nutrients = value!,
                validator: (value) => value!.isEmpty ? 'Please enter nutrient details' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitDietLog,
                child: _isLoading ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)) : Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
