# Food Image Classification for Diabetes App

This service provides food image classification capabilities for the diabetes management application. It uses a Convolutional Neural Network (CNN) to identify food items from images and provides nutritional information.

## Features

- Food image classification using CNN
- Nutritional information extraction
- Integration with the diabetes management app

## Setup Instructions

### Prerequisites

- Python 3.8 or higher
- TensorFlow 2.x
- Flask
- Required Python packages (listed in requirements.txt)

### Installation

1. Install the required Python packages:

```bash
cd ai_services
pip install -r requirements.txt
```

2. Download a pre-trained food classification model or train your own:

For this example, we're using transfer learning with MobileNetV2. You can either:

- Use the Food-101 dataset (https://data.vision.ee.ethz.ch/cvl/food-101.tar.gz)
- Use your own dataset of food images

### Training the Model

If you want to train the model with your own dataset:

1. Organize your dataset in the following structure:
```
food_dataset/
├── train/
│   ├── apple_pie/
│   │   ├── image1.jpg
│   │   ├── image2.jpg
│   │   └── ...
│   ├── pizza/
│   │   ├── image1.jpg
│   │   ├── image2.jpg
│   │   └── ...
│   └── ...
└── validation/
    ├── apple_pie/
    │   ├── image1.jpg
    │   ├── image2.jpg
    │   └── ...
    ├── pizza/
    │   ├── image1.jpg
    │   ├── image2.jpg
    │   └── ...
    └── ...
```

2. Start the Flask service and use the `/prepare_dataset` endpoint to download and prepare a dataset (if using Food-101)

3. Use the `/train` endpoint to train the model

### Running the Service

1. Start the Flask service:

```bash
cd ai_services
chmod +x start_service.sh
./start_service.sh
```

The service will run on http://localhost:5000

## API Endpoints

### 1. Classify Food Image

**Endpoint:** `/classify`

**Method:** POST

**Request Body:**
```json
{
  "image": "base64_encoded_image_string"
}
```

**Response:**
```json
{
  "food": "pizza",
  "confidence": 0.95,
  "calories": 266,
  "nutrients": {
    "carbohydrates": 33.0,
    "protein": 11.0,
    "fat": 10.0,
    "fiber": 2.3,
    "sugar": 3.6
  },
  "description": "Pizza with cheese, tomato sauce, and various toppings"
}
```

### 2. Prepare Dataset

**Endpoint:** `/prepare_dataset`

**Method:** POST

**Response:**
```json
{
  "message": "Dataset preparation would download and extract the Food-101 dataset",
  "dataset_url": "https://data.vision.ee.ethz.ch/cvl/food-101.tar.gz",
  "note": "This is a placeholder. In a real implementation, the dataset would be downloaded and extracted."
}
```

### 3. Create Nutrients Database

**Endpoint:** `/create_nutrients_db`

**Method:** POST

**Response:**
```json
{
  "message": "Sample nutrients database created successfully"
}
```

### 4. Train Model

**Endpoint:** `/train`

**Method:** POST

**Request Body:**
```json
{
  "epochs": 10
}
```

**Response:**
```json
{
  "message": "Model trained successfully"
}
```

## Integration with the Diabetes App

The AI service is integrated with the main diabetes application through:

1. Backend Go API endpoints:
   - `/classify_food_image` - Classifies a food image
   - `/submit_image_and_recommend` - Submits an image and gets dietary recommendations

2. Frontend Flutter screens:
   - Food Image Screen - Allows users to take or select a food image for classification

## Troubleshooting

- If the service fails to start, check if all required packages are installed
- If classification results are poor, consider retraining the model with more data
- For issues with image upload, check the image format and size

## Future Improvements

- Implement more sophisticated CNN architectures
- Expand the food database with more items and detailed nutritional information
- Add support for multiple food items in a single image
- Implement portion size estimation