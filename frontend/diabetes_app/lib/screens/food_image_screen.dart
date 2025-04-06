import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:diabetes_app/services/diet_service.dart';

class FoodImageScreen extends StatefulWidget {
  @override
  _FoodImageScreenState createState() => _FoodImageScreenState();
}

class _FoodImageScreenState extends State<FoodImageScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isClassifying = false;
  
  // For handling both web and mobile platforms
  File? _imageFile;
  Uint8List? _webImage;
  XFile? _pickedFile;
  
  Map<String, dynamic>? _classificationResult;
  
  // Form fields
  double _glucoseLevel = 0;
  String _mealTag = '';
  String _mealType = '';
  String _notes = '';

  final DietService _dietService = DietService();

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
    });

    try {
      _pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );
      
      if (_pickedFile != null) {
        if (kIsWeb) {
          // For web platform
          _webImage = await _pickedFile!.readAsBytes();
          _imageFile = null;
        } else {
          // For mobile platforms
          _imageFile = File(_pickedFile!.path);
          _webImage = null;
        }
        
        setState(() {
          _classificationResult = null; // Reset classification when new image is picked
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _classifyImage() async {
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    setState(() {
      _isClassifying = true;
    });

    try {
      // Convert image to base64 for classification
      String base64Image;
      if (kIsWeb) {
        base64Image = await _dietService.bytesToBase64(_webImage!);
      } else {
        base64Image = await _dietService.imageToBase64(_imageFile!);
      }
      
      final result = await _dietService.classifyFoodImageBase64(base64Image);
      setState(() {
        _classificationResult = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error classifying image: $e')),
      );
    } finally {
      setState(() {
        _isClassifying = false;
      });
    }
  }

  Future<void> _submitAndGetRecommendation() async {
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      // Convert image to base64 for submission
      String base64Image;
      if (kIsWeb) {
        base64Image = await _dietService.bytesToBase64(_webImage!);
      } else {
        base64Image = await _dietService.imageToBase64(_imageFile!);
      }
      
      final recommendation = await _dietService.submitImageAndRecommendBase64(
        base64Image,
        _glucoseLevel,
        _mealTag,
        _mealType,
        _notes,
      );

      Navigator.pushNamed(
        context,
        '/recommendation',
        arguments: recommendation,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Image Analysis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image selection area
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _pickedFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: kIsWeb
                            ? Image.memory(
                                _webImage!,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                _imageFile!,
                                fit: BoxFit.cover,
                              ),
                      )
                    : Center(
                        child: Text('No image selected'),
                      ),
              ),
              SizedBox(height: 16),

              // Image selection buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera_alt),
                    label: Text('Camera'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library),
                    label: Text('Gallery'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading || _pickedFile == null ? null : _classifyImage,
                    icon: Icon(Icons.search),
                    label: Text('Classify'),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Classification results
              if (_isClassifying)
                Center(child: CircularProgressIndicator())
              else if (_classificationResult != null) ...[
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Classification Results',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('Food: ${_classificationResult!['classification']['food']}'),
                        Text('Confidence: ${(_classificationResult!['classification']['confidence'] * 100).toStringAsFixed(2)}%'),
                        Text('Calories: ${_classificationResult!['classification']['calories']}'),
                        Text('Description: ${_classificationResult!['classification']['description']}'),
                        SizedBox(height: 8),
                        Text(
                          'Nutrients:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ..._classificationResult!['classification']['nutrients'].entries.map<Widget>(
                          (entry) => Text('${entry.key}: ${entry.value}'),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],

              // Glucose and meal information form
              Text(
                'Enter Glucose and Meal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(labelText: 'Glucose Level'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _glucoseLevel = double.parse(value!),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter glucose level' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Meal Tag'),
                onSaved: (value) => _mealTag = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter meal tag' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Meal Type'),
                onSaved: (value) => _mealType = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter meal type' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Notes'),
                onSaved: (value) => _notes = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter notes' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading || _pickedFile == null
                    ? null
                    : _submitAndGetRecommendation,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Submit and Get Recommendation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}