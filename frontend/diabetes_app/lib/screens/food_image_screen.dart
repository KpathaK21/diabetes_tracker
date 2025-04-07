import 'dart:io' show File, Platform;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:diabetes_app/services/diet_service.dart';

class FoodImageScreen extends StatefulWidget {
  const FoodImageScreen({super.key});

  @override
  _FoodImageScreenState createState() => _FoodImageScreenState();
}

class _FoodImageScreenState extends State<FoodImageScreen> {
  // Controller for the image path text field
  final TextEditingController _imagePathController = TextEditingController();
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

    // Log platform information for debugging
    String platformInfo = kIsWeb ? 'Web' : Platform.operatingSystem;
    print('📷 Image picking initiated on $platformInfo platform');
    print('📷 Source: ${source == ImageSource.gallery ? 'Gallery' : 'Camera'}');

    try {
      if (source == ImageSource.gallery) {
        // Check if running on macOS
        if (!kIsWeb && Platform.isMacOS) {
          print('🍎 Using file_selector for macOS gallery access');
          
          try {
            // Use file_selector for macOS
            const XTypeGroup typeGroup = XTypeGroup(
              label: 'images',
              extensions: ['jpg', 'jpeg', 'png', 'gif'],
              mimeTypes: ['image/jpeg', 'image/png', 'image/gif'],
            );
            
            print('🍎 Opening file picker dialog with image type filters');
            final XFile? pickedFile = await openFile(
              acceptedTypeGroups: [typeGroup],
            );
            
            if (pickedFile != null) {
              print('🍎 File selected: ${pickedFile.path}');
              print('🍎 File name: ${pickedFile.name}');
              
              _pickedFile = pickedFile;
              _imageFile = File(pickedFile.path);
              _webImage = null;
              
              // Verify file exists and is readable
              bool fileExists = await File(pickedFile.path).exists();
              print('🍎 File exists: $fileExists');
              
              if (!fileExists) {
                print('⚠️ Warning: Selected file does not exist at path: ${pickedFile.path}');
              }
              
              setState(() {
                _classificationResult = null; // Reset classification when new image is picked
              });
              print('🍎 Image successfully loaded from file selector');
            } else {
              print('🍎 No file selected or file picker was cancelled');
            }
          } catch (e, stackTrace) {
            print('⚠️ Error in macOS file selection: $e');
            print('⚠️ Stack trace: $stackTrace');
            rethrow; // Rethrow to be caught by the outer try-catch
          }
        } else {
          // Use ImagePicker for other platforms
          print('📱 Using ImagePicker for ${kIsWeb ? 'web' : Platform.operatingSystem} gallery access');
          
          try {
            final ImagePicker picker = ImagePicker();
            print('📱 Opening image picker with gallery source');
            final XFile? pickedImage = await picker.pickImage(
              source: source,
              imageQuality: 80,
            );
            
            if (pickedImage != null) {
              print('📱 Image selected: ${pickedImage.path}');
              _pickedFile = pickedImage;
              
              if (kIsWeb) {
                // For web platform
                print('🌐 Processing image for web platform');
                _webImage = await pickedImage.readAsBytes();
                print('🌐 Image loaded as bytes, size: ${_webImage!.length} bytes');
                _imageFile = null;
              } else {
                // For non-web platforms
                print('📱 Processing image for mobile platform');
                _imageFile = File(pickedImage.path);
                
                // Verify file exists and is readable
                bool fileExists = await _imageFile!.exists();
                print('📱 File exists: $fileExists');
                
                if (!fileExists) {
                  print('⚠️ Warning: Selected image file does not exist at path: ${pickedImage.path}');
                }
                
                _webImage = null;
              }
              
              setState(() {
                _classificationResult = null; // Reset classification when new image is picked
              });
              print('📱 Image successfully loaded from image picker');
            } else {
              print('📱 No image selected or image picker was cancelled');
            }
          } catch (e, stackTrace) {
            print('⚠️ Error in standard image picking: $e');
            print('⚠️ Stack trace: $stackTrace');
            rethrow; // Rethrow to be caught by the outer try-catch
          }
        }
      } else {
        // Camera access - use ImagePicker for all platforms
        print('📸 Using camera on ${kIsWeb ? 'web' : Platform.operatingSystem} platform');
        
        try {
          final ImagePicker picker = ImagePicker();
          print('📸 Opening camera');
          final XFile? pickedImage = await picker.pickImage(
            source: source,
            imageQuality: 80,
          );
          
          if (pickedImage != null) {
            print('📸 Image captured: ${pickedImage.path}');
            _pickedFile = pickedImage;
            
            if (kIsWeb) {
              // For web platform
              print('🌐 Processing camera image for web platform');
              _webImage = await pickedImage.readAsBytes();
              print('🌐 Camera image loaded as bytes, size: ${_webImage!.length} bytes');
              _imageFile = null;
            } else {
              // For non-web platforms
              print('📱 Processing camera image for ${Platform.operatingSystem} platform');
              _imageFile = File(pickedImage.path);
              
              // Verify file exists and is readable
              bool fileExists = await _imageFile!.exists();
              print('📱 Camera image file exists: $fileExists');
              
              if (!fileExists) {
                print('⚠️ Warning: Captured image file does not exist at path: ${pickedImage.path}');
              }
              
              _webImage = null;
            }
            
            setState(() {
              _classificationResult = null; // Reset classification when new image is picked
            });
            print('📸 Camera image successfully loaded');
          } else {
            print('📸 No image captured or camera was cancelled');
          }
        } catch (e, stackTrace) {
          print('⚠️ Error in camera access: $e');
          print('⚠️ Stack trace: $stackTrace');
          rethrow; // Rethrow to be caught by the outer try-catch
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error picking image: $e');
      print('❌ Stack trace: $stackTrace');
      
      // More detailed error message based on platform and source
      String errorSource = source == ImageSource.gallery ? 'gallery' : 'camera';
      String platformName = kIsWeb ? 'web browser' : Platform.operatingSystem;
      String errorDetails = 'Error accessing $errorSource on $platformName: $e';
      
      print('❌ Detailed error: $errorDetails');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorDetails),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('🏁 Image picking process completed');
    }
  }

  Future<void> _classifyImage() async {
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
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
        const SnackBar(content: Text('Please select an image first')),
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
  
    // Helper method to get color based on glycemic index
    Color getGlycemicIndexColor(dynamic glycemicIndex) {
      int gi = 0;
      if (glycemicIndex is int) {
        gi = glycemicIndex;
      } else if (glycemicIndex is double) {
        gi = glycemicIndex.toInt();
      } else if (glycemicIndex is String) {
        gi = int.tryParse(glycemicIndex) ?? 0;
      }
      
      if (gi <= 0) return Colors.grey; // Unknown or invalid
      if (gi < 55) return Colors.green; // Low GI
      if (gi < 70) return Colors.orange; // Medium GI
      return Colors.red; // High GI
    }
    
    // Helper method to format nutrient names
    String formatNutrientName(String name) {
      // Capitalize first letter and replace underscores with spaces
      if (name.isEmpty) return name;
      name = name.replaceAll('_', ' ');
      return name[0].toUpperCase() + name.substring(1);
    }
    
    // Helper method to get appropriate unit for nutrients
    String getNutrientUnit(String name) {
      // Add units based on nutrient type
      if (name.contains('carb') ||
          name.contains('protein') ||
          name.contains('fat') ||
          name.contains('fiber') ||
          name.contains('sugar')) {
        return 'g';
      } else if (name.contains('sodium') ||
                name.contains('potassium') ||
                name.contains('cholesterol')) {
        return 'mg';
      } else if (name.contains('vitamin') ||
                name.contains('calcium') ||
                name.contains('iron')) {
        return '%';
      }
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Image Analysis'),
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
                    : const Center(
                        child: Text('No image selected'),
                      ),
              ),
              const SizedBox(height: 16),

              // Image selection buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading || _pickedFile == null ? null : _classifyImage,
                    icon: const Icon(Icons.search),
                    label: const Text('Classify'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Classification results
              if (_isClassifying)
                const Center(child: CircularProgressIndicator())
              else if (_classificationResult != null) ...[
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Classification Results',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Food: ${_classificationResult!['classification']['food']}'),
                        Text('Confidence: ${(_classificationResult!['classification']['confidence'] * 100).toStringAsFixed(2)}%'),
                        Text('Calories: ${_classificationResult!['classification']['calories']}'),
                        
                        // Display portion size if available
                        if (_classificationResult!['classification']['portion_size'] != null)
                          Text('Portion Size: ${_classificationResult!['classification']['portion_size']}'),
                        
                        // Display glycemic index if available
                        if (_classificationResult!['classification']['glycemic_index'] != null)
                          Builder(
                            builder: (context) {
                              // Determine color based on glycemic index value
                              final gi = _classificationResult!['classification']['glycemic_index'];
                              Color giColor = Colors.grey;
                              if (gi is int || gi is double) {
                                final giValue = gi is int ? gi : (gi as double).toInt();
                                if (giValue > 0) {
                                  if (giValue < 55) {
                                    giColor = Colors.green;
                                  } else if (giValue < 70) giColor = Colors.orange;
                                  else giColor = Colors.red;
                                }
                              }
                              
                              return Text(
                                'Glycemic Index: ${_classificationResult!['classification']['glycemic_index']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: giColor,
                                ),
                              );
                            },
                          ),
                        
                        Text('Description: ${_classificationResult!['classification']['description']}'),
                        
                        // Display diabetes impact if available
                        if (_classificationResult!['classification']['diabetes_impact'] != null) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Diabetes Impact:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('${_classificationResult!['classification']['diabetes_impact']}',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 8),
                        const Text(
                          'Nutrients:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ..._classificationResult!['classification']['nutrients'].entries.map<Widget>((entry) {
                          // Format nutrient name
                          String name = entry.key;
                          if (name.isNotEmpty) {
                            name = name.replaceAll('_', ' ');
                            name = name[0].toUpperCase() + name.substring(1);
                          }
                          
                          // Add appropriate unit
                          String unit = '';
                          if (name.toLowerCase().contains('carb') ||
                              name.toLowerCase().contains('protein') ||
                              name.toLowerCase().contains('fat') ||
                              name.toLowerCase().contains('fiber') ||
                              name.toLowerCase().contains('sugar')) {
                            unit = 'g';
                          } else if (name.toLowerCase().contains('sodium') ||
                                    name.toLowerCase().contains('potassium') ||
                                    name.toLowerCase().contains('cholesterol')) {
                            unit = 'mg';
                          } else if (name.toLowerCase().contains('vitamin') ||
                                    name.toLowerCase().contains('calcium') ||
                                    name.toLowerCase().contains('iron')) {
                            unit = '%';
                          }
                          
                          return Text('$name: ${entry.value}$unit');
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Glucose and meal information form
              const Text(
                'Enter Glucose and Meal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
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
                onPressed: _isLoading || _pickedFile == null
                    ? null
                    : _submitAndGetRecommendation,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Submit and Get Recommendation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}