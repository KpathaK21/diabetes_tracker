import 'package:flutter/material.dart';
import 'package:diabetes_app/services/diet_service.dart';
import 'package:diabetes_app/services/auth_service.dart';

class AddDietScreen extends StatefulWidget {
  const AddDietScreen({super.key});

  @override
  _AddDietScreenState createState() => _AddDietScreenState();
}

class _AddDietScreenState extends State<AddDietScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _foodDescription = '';
  int _calories = 0;
  String _nutrients = '';
  String _mealTag = '';
  String _mealType = '';
  String _notes = '';
  double _glucoseLevel = 0;

  void _submitDietLog() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      DietService()
          .addDietLogWithGlucose(
            _foodDescription,
            _calories,
            _nutrients,
            _glucoseLevel,
            _mealTag,
            _mealType,
            _notes,
          )
          .then((recommendation) {
        Navigator.pushNamed(
          context,
          '/recommendation',
          arguments: recommendation,
        );
      }).catchError((error) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $error")));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Diet and Glucose Log"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthService().logout(context);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/foodImage');
        },
        tooltip: 'Use Image Classification',
        child: const Icon(Icons.camera_alt),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Food Description'),
                onSaved: (value) => _foodDescription = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter food description' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Calories'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _calories = int.parse(value!),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter calories' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nutrients'),
                onSaved: (value) => _nutrients = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter nutrients' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Glucose Level'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _glucoseLevel = double.parse(value!),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter glucose level' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Meal Tag'),
                onSaved: (value) => _mealTag = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter meal tag' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Meal Type'),
                onSaved: (value) => _mealType = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter meal type' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Notes'),
                onSaved: (value) => _notes = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter notes' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitDietLog,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
