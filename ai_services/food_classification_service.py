import os
import numpy as np
import tensorflow as tf
from tensorflow.keras.models import Sequential, load_model
from tensorflow.keras.layers import Conv2D, MaxPooling2D, Flatten, Dense, Dropout, GlobalAveragePooling2D
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input
from tensorflow.keras.preprocessing import image
import json
from flask import Flask, request, jsonify
import base64
import io
from PIL import Image
import requests
import zipfile
import shutil
import random

app = Flask(__name__)

# Constants
MODEL_PATH = 'food_classification_model.h5'
NUTRIENTS_DB_PATH = 'food_nutrients_db.json'
DATASET_DIR = 'food_dataset'

# Function to generate an unrecognized image response
def unrecognized_image_response():
    print("Generating unrecognized image response")
    
    # Prepare response for unrecognized image
    response = {
        'food': 'unrecognized',
        'confidence': 0.0,
        'calories': 0,
        'nutrients': {},
        'description': 'I cannot recognize the image. Please ensure the image is clear and contains a food item.',
        'glycemic_index': 0,
        'portion_size': 'Unknown',
        'diabetes_impact': 'Unknown impact on blood glucose levels. Please consult with a healthcare professional.'
    }
    
    return jsonify(response)

# Load nutrients database
def load_nutrients_db():
    if os.path.exists(NUTRIENTS_DB_PATH):
        with open(NUTRIENTS_DB_PATH, 'r') as f:
            return json.load(f)
    else:
        # Default empty database
        return {}

# Load the model
def get_model():
    if os.path.exists(MODEL_PATH):
        print("Loading existing model...")
        try:
            model = load_model(MODEL_PATH)
            print("Model loaded successfully!")
            return model
        except Exception as e:
            print(f"Error loading model: {e}")
            print("Please run the training script to create a new model.")
            return None
    
    else:
        print(f"Model file {MODEL_PATH} not found.")
        print("Please run the training script to create a model:")
        print("./train_food_model.sh")
        return None

# Preprocess image for prediction
def preprocess_image(img):
    img = img.resize((224, 224))
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)
    return preprocess_input(img_array)

# Train the model using transfer learning with MobileNetV2
def train_model(train_dir, validation_dir, epochs=20, fine_tune_epochs=5):
    # Create a base model from MobileNetV2
    base_model = MobileNetV2(weights='imagenet', include_top=False, input_shape=(224, 224, 3))
    
    # Freeze the base model
    base_model.trainable = False
    
    # Create a new model on top
    model = Sequential([
        base_model,
        GlobalAveragePooling2D(),
        Dense(256, activation='relu'),  # Increased neurons
        Dropout(0.5),
        Dense(128, activation='relu'),  # Added another layer
        Dropout(0.3),
        Dense(len(os.listdir(train_dir)), activation='softmax')
    ])
    # Compile the model
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss='categorical_crossentropy',
        metrics=['accuracy', tf.keras.metrics.TopKCategoricalAccuracy(k=3, name='top_3_accuracy')]
    )
    
    # Data augmentation for training
    train_datagen = ImageDataGenerator(
        preprocessing_function=preprocess_input,
        rotation_range=20,
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.2,
        zoom_range=0.2,
        horizontal_flip=True,
        fill_mode='nearest'
    )
    
    # Only preprocessing for validation
    validation_datagen = ImageDataGenerator(
        preprocessing_function=preprocess_input
    )
    
    # Create data generators
    train_generator = train_datagen.flow_from_directory(
        train_dir,
        target_size=(224, 224),
        batch_size=32,
        class_mode='categorical'
    )
    
    validation_generator = validation_datagen.flow_from_directory(
        validation_dir,
        target_size=(224, 224),
        batch_size=32,
        class_mode='categorical'
    )
    
    # Train the model
    print("Training the top layers...")
    history = model.fit(
        train_generator,
        steps_per_epoch=train_generator.samples // 32,
        epochs=epochs,
        validation_data=validation_generator,
        validation_steps=validation_generator.samples // 32,
        callbacks=[
            tf.keras.callbacks.EarlyStopping(monitor='val_accuracy', patience=5, restore_best_weights=True),
            tf.keras.callbacks.ReduceLROnPlateau(monitor='val_loss', factor=0.2, patience=3, min_lr=0.00001)
        ]
    )
    
    # Fine-tuning
    # Unfreeze the top layers of the base model
    print("Fine-tuning the model...")
    base_model.trainable = True
    
    # Freeze all the layers except the last 4
    for layer in base_model.layers[:-4]:
        layer.trainable = False
        
    # Recompile the model with a lower learning rate
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.0001),
        loss='categorical_crossentropy',
        metrics=['accuracy', tf.keras.metrics.TopKCategoricalAccuracy(k=3, name='top_3_accuracy')]
    )
    
    # Continue training
    history_fine = model.fit(
        train_generator,
        steps_per_epoch=train_generator.samples // 32,
        epochs=fine_tune_epochs,
        validation_data=validation_generator,
        validation_steps=validation_generator.samples // 32,
        callbacks=[
            tf.keras.callbacks.EarlyStopping(monitor='val_accuracy', patience=3, restore_best_weights=True)
        ]
    )
    
    # Save the model
    model.save(MODEL_PATH)
    
    # Save class indices
    with open('class_indices.json', 'w') as f:
        json.dump(train_generator.class_indices, f)
    
    return model

# API endpoint for image classification
@app.route('/classify', methods=['POST'])
def classify_image():
    if 'image' not in request.json:
        return jsonify({'error': 'No image provided'}), 400
    
    try:
        # Get the base64 encoded image
        img_data = request.json['image']
        print(f"Received image data of length: {len(img_data)}")
        
        # Handle potential padding issues with base64
        # Add padding if needed
        padding = 4 - (len(img_data) % 4) if len(img_data) % 4 != 0 else 0
        img_data += '=' * padding
        
        # Remove data URL prefix if present
        if img_data.startswith('data:image'):
            img_data = img_data.split(',')[1]
        
        try:
            img_bytes = base64.b64decode(img_data)
            print(f"Successfully decoded base64 data, length: {len(img_bytes)} bytes")
            
            try:
                img = Image.open(io.BytesIO(img_bytes))
                print(f"Successfully opened image: {img.format}, size: {img.size}, mode: {img.mode}")
            except Exception as e:
                print(f"Error opening image: {str(e)}")
                # Return unrecognized image response instead of failing
                print(f"Cannot process image: {str(e)}")
                return unrecognized_image_response()
        except Exception as e:
            print(f"Error decoding base64: {str(e)}")
            # Return unrecognized image response instead of failing
            return unrecognized_image_response()
        
        # Load the model
        model = get_model()
        
        # If model is not available, return error message
        if model is None:
            print("Model not available. Cannot classify image.")
            return jsonify({
                'error': 'Model not available',
                'message': 'The food classification model has not been trained yet. Please run the training script: ./train_food_model.sh'
            }), 503  # Service Unavailable
        
        # If model is available, use it for prediction
        processed_img = preprocess_image(img)
        prediction = model.predict(processed_img)
        
        # Try to load class indices
        try:
            with open('class_indices.json', 'r') as f:
                class_indices = json.load(f)
            
            # Invert the class indices dictionary
            class_names = {v: k for k, v in class_indices.items()}
            
            # Get the predicted class
            predicted_class_index = np.argmax(prediction[0])
            predicted_class = class_names[predicted_class_index]
            confidence = float(prediction[0][predicted_class_index])
        except Exception as e:
            # If class indices file doesn't exist, return unrecognized image response
            print(f"Error loading class indices: {e}")
            return unrecognized_image_response()
        
        # Get nutrients information
        nutrients_db = load_nutrients_db()
        nutrients_info = nutrients_db.get(predicted_class, {})
        
        # Prepare enhanced response
        response = {
            'food': predicted_class,
            'confidence': confidence,
            'calories': nutrients_info.get('calories', 0),
            'nutrients': nutrients_info.get('nutrients', {}),
            'description': nutrients_info.get('description', f'This appears to be {predicted_class}'),
            'glycemic_index': nutrients_info.get('glycemic_index', 0),
            'portion_size': nutrients_info.get('portion_size', 'Unknown'),
            'diabetes_impact': nutrients_info.get('diabetes_impact', 'Unknown impact on blood glucose levels')
        }
        
        return jsonify(response)
        
    except Exception as e:
        print(f"Error in classify_image: {str(e)}")
        # Return unrecognized image response for any unexpected errors
        return unrecognized_image_response()

# API endpoint for downloading and preparing the dataset
@app.route('/prepare_dataset', methods=['POST'])
def prepare_dataset():
    try:
        # Create dataset directory if it doesn't exist
        if not os.path.exists(DATASET_DIR):
            os.makedirs(DATASET_DIR)
            
        # For this example, we'll use the Food-101 dataset
        dataset_url = "https://data.vision.ee.ethz.ch/cvl/food-101.tar.gz"
        dataset_path = os.path.join(os.getcwd(), "food-101.tar.gz")
        
        # Check if request contains a custom dataset URL
        if 'dataset_url' in request.json:
            dataset_url = request.json['dataset_url']
        
        # Download the dataset
        print(f"Downloading dataset from {dataset_url}...")
        try:
            response = requests.get(dataset_url, stream=True)
            total_size = int(response.headers.get('content-length', 0))
            
            with open(dataset_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
            
            print(f"Dataset downloaded to {dataset_path}")
            
            # Extract the dataset
            print("Extracting dataset...")
            if dataset_path.endswith('.tar.gz'):
                import tarfile
                with tarfile.open(dataset_path) as tar:
                    tar.extractall(path=os.getcwd())
                print("Dataset extracted")
            elif dataset_path.endswith('.zip'):
                with zipfile.ZipFile(dataset_path, 'r') as zip_ref:
                    zip_ref.extractall(os.getcwd())
                print("Dataset extracted")
                
            # Organize the dataset into train and validation directories
            print("Organizing dataset...")
            organize_dataset()
            
            return jsonify({
                'message': 'Dataset downloaded and prepared successfully',
                'dataset_url': dataset_url
            })
        except Exception as e:
            print(f"Error downloading or extracting dataset: {e}")
            # For demonstration, return a message
            return jsonify({
                'message': 'Error preparing dataset. Using placeholder dataset structure.',
                'error': str(e)
            })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# API endpoint for creating a sample nutrients database
@app.route('/create_nutrients_db', methods=['POST'])
def create_nutrients_db():
    try:
        # Create an enhanced nutrients database
        nutrients_db = {
            "pizza": {
                "calories": 266,
                "nutrients": {
                    "carbohydrates": 33.0,
                    "protein": 11.0,
                    "fat": 10.0,
                    "fiber": 2.3,
                    "sugar": 3.6,
                    "sodium": 598.0,
                    "potassium": 184.0,
                    "cholesterol": 17.0,
                    "vitamin_a": 5.0,
                    "vitamin_c": 2.0,
                    "calcium": 18.0,
                    "iron": 10.0
                },
                "glycemic_index": 60,
                "portion_size": "1 slice (107g)",
                "description": "Pizza with cheese, tomato sauce, and various toppings",
                "diabetes_impact": "Moderate glycemic impact. The combination of cheese and refined flour crust can raise blood glucose levels."
            },
            "salad": {
                "calories": 152,
                "nutrients": {
                    "carbohydrates": 11.0,
                    "protein": 3.8,
                    "fat": 11.0,
                    "fiber": 3.0,
                    "sugar": 2.5,
                    "sodium": 170.0,
                    "potassium": 350.0,
                    "cholesterol": 0.0,
                    "vitamin_a": 70.0,
                    "vitamin_c": 40.0,
                    "calcium": 5.0,
                    "iron": 8.0
                },
                "glycemic_index": 15,
                "portion_size": "1 bowl (150g)",
                "description": "Mixed greens with vegetables and dressing",
                "diabetes_impact": "Low glycemic impact. High fiber content helps slow glucose absorption."
            },
            "apple_pie": {
                "calories": 237,
                "nutrients": {
                    "carbohydrates": 33.6,
                    "protein": 2.4,
                    "fat": 11.0,
                    "fiber": 1.4,
                    "sugar": 18.9,
                    "sodium": 170.0,
                    "potassium": 100.0,
                    "cholesterol": 0.0,
                    "vitamin_a": 1.0,
                    "vitamin_c": 2.0,
                    "calcium": 1.0,
                    "iron": 4.0
                },
                "glycemic_index": 65,
                "portion_size": "1 slice (125g)",
                "description": "Apple pie with a sweet filling of apple, sugar, and cinnamon",
                "diabetes_impact": "High glycemic impact due to sugar content and refined flour crust."
            }
        }
        
        # Check if we should use the full enhanced database
        use_full_db = request.json.get('use_full_db', True)
        
        if use_full_db:
            # Import the create_nutrients_db module to get the full database
            import importlib.util
            spec = importlib.util.spec_from_file_location("create_nutrients_db", "create_nutrients_db.py")
            create_nutrients_db_module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(create_nutrients_db_module)
            
            # Use the full nutrients database from the module
            nutrients_db = create_nutrients_db_module.nutrients_db
        
        # Save the nutrients database
        with open(NUTRIENTS_DB_PATH, 'w') as f:
            json.dump(nutrients_db, f, indent=4)
        
        return jsonify({
            'message': 'Enhanced nutrients database created successfully',
            'food_items_count': len(nutrients_db),
            'sample_items': list(nutrients_db.keys())[:5]
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500
# Function to organize dataset into train and validation directories
def organize_dataset():
    # This function organizes the Food-101 dataset or a custom dataset
    # into train and validation directories
    
    # For Food-101, the structure is:
    # food-101/
    #   images/
    #     class1/
    #     class2/
    #   meta/
    #     classes.txt
    #     train.json
    #     test.json
    
    # Create train and validation directories
    train_dir = os.path.join(DATASET_DIR, 'train')
    validation_dir = os.path.join(DATASET_DIR, 'validation')
    
    if not os.path.exists(train_dir):
        os.makedirs(train_dir)
    if not os.path.exists(validation_dir):
        os.makedirs(validation_dir)
    
    # Check if we have the Food-101 dataset
    if os.path.exists('food-101'):
        print("Organizing Food-101 dataset...")
        
        # Read classes
        with open('food-101/meta/classes.txt', 'r') as f:
            classes = [line.strip() for line in f.readlines()]
        
        # Read train and test splits
        import json
        with open('food-101/meta/train.json', 'r') as f:
            train_data = json.load(f)
        with open('food-101/meta/test.json', 'r') as f:
            test_data = json.load(f)
        
        # Create class directories and copy images
        for food_class in classes:
            # Create directories
            os.makedirs(os.path.join(train_dir, food_class), exist_ok=True)
            os.makedirs(os.path.join(validation_dir, food_class), exist_ok=True)
            
            # Copy train images (just create symlinks to save space)
            train_images = [img for img in train_data[food_class]]
            for img in train_images:
                src = os.path.join('food-101/images', f"{img}.jpg")
                dst = os.path.join(train_dir, food_class, f"{img}.jpg")
                if os.path.exists(src) and not os.path.exists(dst):
                    os.symlink(os.path.abspath(src), dst)
            
            # Copy validation images (just create symlinks to save space)
            val_images = [img for img in test_data[food_class]]
            for img in val_images:
                src = os.path.join('food-101/images', f"{img}.jpg")
                dst = os.path.join(validation_dir, food_class, f"{img}.jpg")
                if os.path.exists(src) and not os.path.exists(dst):
                    os.symlink(os.path.abspath(src), dst)
    else:
        print("Food-101 dataset not found. Using custom dataset organization...")
        # Here you would implement custom dataset organization logic
        # For now, we'll just create some example directories
        
        sample_classes = ['pizza', 'salad', 'sandwich', 'apple_pie', 'rice']
        for food_class in sample_classes:
            os.makedirs(os.path.join(train_dir, food_class), exist_ok=True)
            os.makedirs(os.path.join(validation_dir, food_class), exist_ok=True)

# API endpoint for training the model
@app.route('/train', methods=['POST'])
def train():
    try:
        # Check if dataset exists
        if not os.path.exists(DATASET_DIR):
            return jsonify({'error': 'Dataset not found. Please prepare the dataset first.'}), 400
        
        # Check if train and validation directories exist
        train_dir = os.path.join(DATASET_DIR, 'train')
        validation_dir = os.path.join(DATASET_DIR, 'validation')
        
        if not os.path.exists(train_dir) or not os.path.exists(validation_dir):
            return jsonify({'error': 'Train or validation directory not found. Please prepare the dataset first.'}), 400
        
        # Get training parameters
        epochs = request.json.get('epochs', 20)
        fine_tune_epochs = request.json.get('fine_tune_epochs', 5)
        
        # Train the model
        train_model(train_dir, validation_dir, epochs, fine_tune_epochs)
        
        return jsonify({'message': 'Model trained successfully'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500
if __name__ == '__main__':
    import os
    import sys
    
    # Get port from environment variable or command line argument
    port = 5002  # Default port
    
    # Check for port in environment variable
    if 'FLASK_RUN_PORT' in os.environ:
        try:
            port = int(os.environ['FLASK_RUN_PORT'])
            print(f"Using port {port} from environment variable FLASK_RUN_PORT")
        except ValueError:
            print(f"Invalid port in environment variable: {os.environ['FLASK_RUN_PORT']}")
    
    # Check for port in command line arguments
    for i, arg in enumerate(sys.argv):
        if arg == '--port' and i + 1 < len(sys.argv):
            try:
                port = int(sys.argv[i + 1])
                print(f"Using port {port} from command line argument")
            except ValueError:
                print(f"Invalid port in command line argument: {sys.argv[i + 1]}")
    
    print(f"Starting food classification service on port {port}...")
    app.run(host='0.0.0.0', port=port, debug=True)
    app.run(host='0.0.0.0', port=5002, debug=True)