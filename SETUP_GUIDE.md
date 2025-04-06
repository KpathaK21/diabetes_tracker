# Image Classification Feature Setup Guide

This guide will help you set up and use the new image classification feature for your diabetes management application. This feature allows users to upload images of their meals and automatically get nutritional information. The feature is compatible with both mobile platforms and web browsers.

## Overview of Changes

We've implemented the following components:

1. **AI Service**: A Python-based Flask API that handles food image classification using a CNN model
2. **Backend Integration**: New Go endpoints to handle image uploads and communicate with the AI service
3. **Frontend Updates**: New Flutter screens and functionality for image upload and display of classification results

## Setup Instructions

### 1. Set Up the AI Service

First, you need to set up the Python-based AI service:

```bash
# Navigate to the AI services directory
cd ai_services

# Install the required Python packages
pip install -r requirements.txt

# Make the start script executable
chmod +x start_service.sh

# Start the AI service
./start_service.sh
```

The AI service will run on http://localhost:5000

**Note**: The AI service includes a mock implementation that works without training a model. It will randomly select food items from the nutrients database for testing purposes.

### 2. Update the Go Backend

The backend changes have already been implemented. You just need to restart your Go server:

```bash
# Navigate to the backend directory
cd backend

# Run the Go server
go run *.go
```

The backend server will run on http://localhost:8080

### 3. Update the Flutter Frontend

The frontend changes have already been implemented. You need to update the dependencies and run the app:

```bash
# Navigate to the Flutter app directory
cd frontend/diabetes_app

# Get the new dependencies
flutter pub get

# Run the app
flutter run
```

## Using the Image Classification Feature

1. **Login to the app** using your credentials
2. **Navigate to the "Add Diet" screen**
3. **Tap the camera icon** in the bottom right corner to access the Food Image screen
4. **Take a photo or select an image** from your gallery
5. **Tap "Classify"** to analyze the food image
6. **Review the classification results** showing the identified food, calories, and nutrients
7. **Enter your glucose information**
8. **Tap "Submit and Get Recommendation"** to get personalized dietary recommendations

## Training Your Own Model

If you want to train the model with your own dataset:

1. Organize your dataset in the required structure (see ai_services/README.md for details)
2. Use the API endpoints to prepare the dataset and train the model:
   - `/prepare_dataset` - Prepares the dataset
   - `/create_nutrients_db` - Creates a sample nutrients database
   - `/train` - Trains the model

## Web Platform Compatibility

The image classification feature has been designed to work on both mobile platforms and web browsers. Here are some key points about web compatibility:

1. **Image Selection**: On web platforms, the image picker will open a file dialog instead of accessing the camera directly.

2. **Image Processing**: The app handles images differently on web vs. mobile:
   - On mobile: Uses the File API to process images
   - On web: Uses Uint8List byte arrays to handle image data

3. **Browser Limitations**: Some browsers may have limitations regarding camera access. Make sure to:
   - Use HTTPS for better camera access permissions
   - Request appropriate permissions from the user
   - Test on different browsers (Chrome, Firefox, Safari)

4. **Performance Considerations**: Image processing might be slower on web platforms compared to native mobile apps. Consider optimizing image size and quality for better performance.

## Troubleshooting

### AI Service Issues

- **Service won't start**: Check if all required Python packages are installed
- **Classification errors**: The model may need more training data or fine-tuning
- **"AI service returned error"**: Make sure the AI service is running on port 5000 and the nutrients database exists

### Backend Issues

- **Image upload fails**: Check the image size and format
- **Connection errors**: Ensure the AI service is running on port 5000

### Frontend Issues

- **Camera access denied**: Check app permissions for camera access
- **Image picker crashes**: Ensure the image_picker package is properly installed

## Next Steps and Future Improvements

1. **Expand the food database** with more items and detailed nutritional information
2. **Improve the model accuracy** by training with more diverse food images
3. **Add portion size estimation** to provide more accurate nutritional information
4. **Implement multi-food detection** to identify multiple food items in a single image

## Technical Details

### AI Service

- Built with Flask, TensorFlow, and MobileNetV2
- Uses transfer learning for efficient training
- Provides RESTful API endpoints for classification and training
- Includes a mock implementation for testing without a trained model

### Backend Integration

- New endpoints in the Go server for handling image uploads
- Base64 encoding/decoding for image transfer
- Integration with existing recommendation system

### Frontend Updates

- New FoodImageScreen for image capture and display
- Integration with device camera and gallery
- Display of classification results and nutritional information
- Cross-platform compatibility for both mobile and web

For more detailed information, refer to the README files in each component directory.