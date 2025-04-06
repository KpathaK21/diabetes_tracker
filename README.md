# Diabetes Tracker Application

## Overview

The Diabetes Tracker Application is a comprehensive health management system designed to help individuals with diabetes monitor and manage their condition effectively. The application leverages modern technologies including machine learning for food image classification, personalized recommendations, and comprehensive health tracking.

## Features

- **Glucose Monitoring**: Track blood glucose levels over time with visual analytics
- **Dietary Management**: Log meals and track nutritional intake
- **Food Image Classification**: Take photos of meals to automatically identify food items and their nutritional content
- **Personalized Recommendations**: Receive AI-powered dietary and lifestyle recommendations
- **Appointment Scheduling**: Manage healthcare appointments
- **Medication Tracking**: Monitor medication schedules and adherence
- **Medical Profile Management**: Store and manage medical information
- **Cross-Platform Support**: Available on iOS, Android, web, and desktop platforms

## Project Structure

The project is organized into three main components:

### 1. Backend (Go)
- RESTful API for handling client requests
- PostgreSQL database integration
- JWT authentication
- Integration with AI services

### 2. AI Services (Python)
- Food image classification using CNN with transfer learning
- Nutritional information extraction
- Glycemic index assessment
- Diabetes impact analysis

### 3. Frontend (Flutter)
- Cross-platform mobile and web application
- User-friendly interface
- Real-time data visualization
- Camera integration for food image capture

## Prerequisites

Before setting up the project, ensure you have the following installed:

- **Go** (1.16 or higher)
- **Python** (3.8 or higher)
- **Flutter** (latest stable version)
- **PostgreSQL** (12 or higher)
- **Git** (for cloning the repository)

## Installation and Setup

### Cloning the Repository

```bash
# Clone the repository
git clone https://github.com/yourusername/diabetes-tracker.git

# Navigate to the project directory
cd diabetes-tracker
```

### Setting Up the Backend

```bash
# Navigate to the backend directory
cd backend

# Copy the example environment file
cp .env.example .env

# Edit the .env file with your database credentials and other settings
# Use your favorite text editor
nano .env

# Install Go dependencies
go mod download

# Run the backend server
go run *.go
```

The backend server will run on http://localhost:8080

### Setting Up the AI Service

```bash
# Navigate to the AI services directory
cd ai_services

# Create a Python virtual environment
python -m venv tensorflow_env

# Activate the virtual environment
# On Windows
tensorflow_env\Scripts\activate
# On macOS/Linux
source tensorflow_env/bin/activate

# Install the required Python packages
pip install -r requirements.txt

# Create the nutrients database
python create_nutrients_db.py

# Start the AI service
# For full service (requires trained model)
chmod +x start_enhanced_service.sh
./start_enhanced_service.sh

# OR for mock service (for testing without a trained model)
chmod +x start_enhanced_mock_service.sh
./start_enhanced_mock_service.sh
```

The AI service will run on http://localhost:5000 (full service) or http://localhost:5001 (mock service)

### Setting Up the Frontend

```bash
# Navigate to the Flutter app directory
cd frontend/diabetes_app

# Get the Flutter dependencies
flutter pub get

# Run the app in debug mode
flutter run

# Or build for a specific platform
flutter build ios
flutter build apk
flutter build web
```

## Training the Food Classification Model

If you want to train the food classification model with your own dataset:

```bash
# Navigate to the AI services directory
cd ai_services

# Download the Food-101 dataset (if not using your own)
# This is a large download (5GB+)
wget https://data.vision.ee.ethz.ch/cvl/food-101.tar.gz
tar -xzf food-101.tar.gz

# Run the training script
chmod +x train_food_model.sh
./train_food_model.sh
```

Alternatively, you can use the API endpoints to prepare the dataset and train the model:
- `/prepare_dataset` - Prepares the dataset
- `/create_nutrients_db` - Creates a sample nutrients database
- `/train` - Trains the model

## Usage

### User Registration and Login

1. Open the application on your device
2. Create a new account or log in with existing credentials
3. Complete your medical profile with relevant diabetes information

### Tracking Glucose Levels

1. Navigate to the Glucose section
2. Add new glucose readings with date, time, and value
3. View trends and analytics of your glucose levels over time

### Food Tracking with Image Classification

1. Navigate to the "Add Diet" screen
2. Tap the camera icon to access the Food Image screen
3. Take a photo or select an image from your gallery
4. Tap "Classify" to analyze the food image
5. Review the classification results showing the identified food, calories, and nutrients
6. Enter your glucose information
7. Tap "Submit and Get Recommendation" to get personalized dietary recommendations

### Medication and Appointment Management

1. Use the Medication section to track your diabetes medications
2. Schedule and manage healthcare appointments in the Appointments section

## API Documentation

### Backend API Endpoints

The backend provides RESTful API endpoints for all application features:

- **Authentication**: `/api/auth/register`, `/api/auth/login`
- **User Profile**: `/api/user/profile`, `/api/user/update`
- **Glucose**: `/api/glucose/add`, `/api/glucose/history`
- **Diet**: `/api/diet/add`, `/api/diet/history`
- **Food Classification**: `/api/classify_food_image`
- **Recommendations**: `/api/recommendations`
- **Medications**: `/api/medications/*`
- **Appointments**: `/api/appointments/*`

### AI Service API Endpoints

The AI service provides endpoints for food classification and model training:

- **Classify Food Image**: `/classify` (POST)
- **Prepare Dataset**: `/prepare_dataset` (POST)
- **Create Nutrients Database**: `/create_nutrients_db` (POST)
- **Train Model**: `/train` (POST)

## Troubleshooting

### Backend Issues

- **Database connection errors**: Check your PostgreSQL connection settings in the .env file
- **JWT token issues**: Ensure your JWT secret is properly set in the .env file
- **API errors**: Check the backend logs for detailed error messages

### AI Service Issues

- **Service won't start**: Check if all required Python packages are installed
- **Classification errors**: The model may need more training data or fine-tuning
- **"AI service returned error"**: Make sure the AI service is running and the nutrients database exists

### Frontend Issues

- **Build errors**: Run `flutter clean` followed by `flutter pub get`
- **Camera access denied**: Check app permissions for camera access
- **Image picker crashes**: Ensure the image_picker package is properly installed
- **Connection errors**: Verify that the backend and AI services are running

## Contributing

We welcome contributions to the Diabetes Tracker Application! Here's how you can contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure your code follows the project's coding standards and includes appropriate tests.

## Future Improvements

- **Enhanced AI Models**: Implement more sophisticated CNN architectures
- **Multiple Food Detection**: Add support for identifying multiple food items in a single image
- **Portion Size Estimation**: Implement more accurate portion size estimation
- **Integration with CGM Devices**: Connect with continuous glucose monitoring devices
- **Expanded Food Database**: Add more food items and detailed nutritional information
- **Advanced Analytics**: Provide deeper insights into glucose patterns and dietary impacts
- **Social Features**: Add community support and sharing capabilities

---

## Acknowledgments

- Food-101 dataset from ETH Zurich
- TensorFlow and MobileNetV2 for image classification
- Flutter team for the amazing cross-platform framework
- All contributors who have helped shape this project
