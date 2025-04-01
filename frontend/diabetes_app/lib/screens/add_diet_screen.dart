// File: lib/screens/add_diet_screen.dart
import 'package:flutter/material.dart';
import 'package:diabetes_app/services/diet_service.dart';

class AddDietScreen extends StatefulWidget {
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

      DietService().addDietLogWithGlucose(
        _foodDescription,
        _calories,
        _nutrients,
        _glucoseLevel,
        _mealTag,
        _mealType,
        _notes,
      ).then((recommendation) {
        Navigator.pushNamed(
          context,
          '/recommendation',
          arguments: recommendation,
        );
      }).catchError((error) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to add diet log: \$error")));
      }).whenComplete(() => setState(() => _isLoading = false));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Diet and Glucose Log")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Food Description'),
                onSaved: (value) => _foodDescription = value!,
                validator: (value) => value!.isEmpty ? 'Please enter some text' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Calories'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _calories = int.parse(value!),
                validator: (value) => value!.isEmpty ? 'Please enter calories' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Nutrients'),
                onSaved: (value) => _nutrients = value!,
                validator: (value) => value!.isEmpty ? 'Please enter nutrient details' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Glucose Level (mg/dL)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _glucoseLevel = double.parse(value!),
                validator: (value) => value!.isEmpty ? 'Please enter glucose level' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Meal Tag'),
                onSaved: (value) => _mealTag = value!,
                validator: (value) => value!.isEmpty ? 'Please enter meal tag' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Meal Type'),
                onSaved: (value) => _mealType = value!,
                validator: (value) => value!.isEmpty ? 'Please specify the type of meal' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Notes'),
                onSaved: (value) => _notes = value!,
                validator: (value) => value!.isEmpty ? 'Please add any relevant notes' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitDietLog,
                child: _isLoading ? CircularProgressIndicator() : Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




// // File: lib/screens/add_diet_screen.dart
// import 'package:flutter/material.dart';
// import 'package:diabetes_app/services/diet_service.dart';  // Make sure the import path is correct
// 
// class AddDietScreen extends StatefulWidget {
//   @override
//   _AddDietScreenState createState() => _AddDietScreenState();
// }
// 
// class _AddDietScreenState extends State<AddDietScreen> {
//   final _formKey = GlobalKey<FormState>();
//   bool _isLoading = false;
//   String _foodDescription = '';
//   int _calories = 0;
//   String _nutrients = '';
//   String _mealTag = '';
//   String _mealType = '';
//   String _notes = '';
//   double _glucoseLevel = 0;  // Added for glucose level
// 
// 	void _submitDietLog() {
// 	  if (_formKey.currentState!.validate()) {
// 	    _formKey.currentState!.save();
// 	    setState(() => _isLoading = true);
// 
// 	    DietService().addDietLogWithGlucose(
// 	      _foodDescription,
// 	      _calories,
// 	      _nutrients,
// 	      _glucoseLevel,  // Make sure this variable is defined in your state class
// 	      _mealTag,
// 	      _mealType,
// 	      _notes
// 	    ).then((_) {
// 	      Navigator.pushNamed(context, '/recommendation'); 
// 	    }).catchError((error) {
// 	      setState(() => _isLoading = false);
// 	      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to add diet log: $error")));
// 	    }).whenComplete(() => setState(() => _isLoading = false));
// 	  }
// 	}
// 
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Add Diet and Glucose Log")),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: <Widget>[
//               TextFormField(
//                 decoration: InputDecoration(labelText: 'Food Description'),
//                 onSaved: (value) => _foodDescription = value!,
//                 validator: (value) => value!.isEmpty ? 'Please enter some text' : null,
//               ),
//               TextFormField(
//                 decoration: InputDecoration(labelText: 'Calories'),
//                 keyboardType: TextInputType.number,
//                 onSaved: (value) => _calories = int.parse(value!),
//                 validator: (value) => value!.isEmpty ? 'Please enter calories' : null,
//               ),
//               TextFormField(
//                 decoration: InputDecoration(labelText: 'Nutrients'),
//                 onSaved: (value) => _nutrients = value!,
//                 validator: (value) => value!.isEmpty ? 'Please enter nutrient details' : null,
//               ),
//               TextFormField(
//                 decoration: InputDecoration(labelText: 'Glucose Level (mg/dL)'),
//                 keyboardType: TextInputType.number,
//                 onSaved: (value) => _glucoseLevel = double.parse(value!),
//                 validator: (value) => value!.isEmpty ? 'Please enter glucose level' : null,
//               ),
//               TextFormField(
//                 decoration: InputDecoration(labelText: 'Meal Tag'),
//                 onSaved: (value) => _mealTag = value!,
//                 validator: (value) => value!.isEmpty ? 'Please enter meal tag' : null,
//               ),
//               TextFormField(
//                 decoration: InputDecoration(labelText: 'Meal Type'),
//                 onSaved: (value) => _mealType = value!,
//                 validator: (value) => value!.isEmpty ? 'Please specify the type of meal' : null,
//               ),
//               TextFormField(
//                 decoration: InputDecoration(labelText: 'Notes'),
//                 onSaved: (value) => _notes = value!,
//                 validator: (value) => value!.isEmpty ? 'Please add any relevant notes' : null,
//               ),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _isLoading ? null : _submitDietLog,
//                 child: _isLoading ? CircularProgressIndicator() : Text('Submit'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
