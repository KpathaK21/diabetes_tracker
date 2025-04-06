import os
import numpy as np
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Conv2D, MaxPooling2D, Flatten, Dense, Dropout, GlobalAveragePooling2D
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input
from tensorflow.keras.preprocessing import image
import json
import requests
import tarfile
import shutil
import time

# Constants
MODEL_PATH = 'food_classification_model.h5'
CLASS_INDICES_PATH = 'class_indices.json'
DATASET_DIR = 'food_dataset'

print("TensorFlow version:", tf.__version__)
print("GPU Available:", tf.config.list_physical_devices('GPU'))

# Function to organize dataset into train and validation directories
def organize_dataset():
    # This function organizes the Food-101 dataset into train and validation directories
    print("Organizing Food-101 dataset...")
    
    # Create train and validation directories
    train_dir = os.path.join(DATASET_DIR, 'train')
    validation_dir = os.path.join(DATASET_DIR, 'validation')
    
    if not os.path.exists(train_dir):
        os.makedirs(train_dir)
    if not os.path.exists(validation_dir):
        os.makedirs(validation_dir)
    
    # Check if we have the Food-101 dataset
    if os.path.exists('food-101'):
        print("Found Food-101 dataset, organizing...")
        
        # Read classes
        with open('food-101/meta/classes.txt', 'r') as f:
            classes = [line.strip() for line in f.readlines()]
        
        # Read train and test splits
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
            for img in train_images[:min(500, len(train_images))]:  # Limit to 500 images per class for faster training
                # Extract just the image ID from the path
                img_id = img.split('/')[-1]
                
                src = os.path.join('food-101/images', food_class, f"{img_id}.jpg")
                dst = os.path.join(train_dir, food_class, f"{img_id}.jpg")
                
                if os.path.exists(src) and not os.path.exists(dst):
                    os.symlink(os.path.abspath(src), dst)
            
            # Copy validation images (just create symlinks to save space)
            val_images = [img for img in test_data[food_class]]
            for img in val_images[:min(100, len(val_images))]:  # Limit to 100 images per class for faster training
                # Extract just the image ID from the path
                img_id = img.split('/')[-1]
                
                src = os.path.join('food-101/images', food_class, f"{img_id}.jpg")
                dst = os.path.join(validation_dir, food_class, f"{img_id}.jpg")
                
                if os.path.exists(src) and not os.path.exists(dst):
                    os.symlink(os.path.abspath(src), dst)
        
        print(f"Dataset organized with {len(classes)} classes")
        return True
    else:
        print("Food-101 dataset not found.")
        return False

# Function to download and extract the Food-101 dataset
def download_dataset():
    if not os.path.exists('food-101'):
        print("Downloading Food-101 dataset...")
        dataset_url = "https://data.vision.ee.ethz.ch/cvl/food-101.tar.gz"
        dataset_path = "food-101.tar.gz"
        
        # Check if the tar.gz file already exists
        if not os.path.exists(dataset_path):
            response = requests.get(dataset_url, stream=True)
            total_size = int(response.headers.get('content-length', 0))
            
            with open(dataset_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
            
            print(f"Dataset downloaded to {dataset_path}")
        else:
            print(f"Dataset file {dataset_path} already exists, skipping download")
        
        # Extract the dataset
        print("Extracting dataset...")
        with tarfile.open(dataset_path) as tar:
            tar.extractall(path=os.getcwd())
        
        print("Dataset extracted")
        return True
    else:
        print("Food-101 dataset already exists")
        return True

# Train the model using transfer learning with MobileNetV2
def train_model(train_dir, validation_dir, epochs=10, fine_tune_epochs=5):
    print("Starting model training...")
    
    # Count the number of classes
    num_classes = len(os.listdir(train_dir))
    print(f"Training with {num_classes} classes")
    
    # Create a base model from MobileNetV2
    base_model = MobileNetV2(weights='imagenet', include_top=False, input_shape=(224, 224, 3))
    
    # Freeze the base model
    base_model.trainable = False
    
    # Create a new model on top
    model = Sequential([
        base_model,
        GlobalAveragePooling2D(),
        Dense(256, activation='relu'),
        Dropout(0.5),
        Dense(128, activation='relu'),
        Dropout(0.3),
        Dense(num_classes, activation='softmax')
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
        steps_per_epoch=min(train_generator.samples // 32, 100),  # Limit steps for faster training
        epochs=epochs,
        validation_data=validation_generator,
        validation_steps=min(validation_generator.samples // 32, 50),  # Limit steps for faster training
        callbacks=[
            tf.keras.callbacks.EarlyStopping(monitor='val_accuracy', patience=3, restore_best_weights=True),
            tf.keras.callbacks.ReduceLROnPlateau(monitor='val_loss', factor=0.2, patience=2, min_lr=0.00001)
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
        steps_per_epoch=min(train_generator.samples // 32, 100),  # Limit steps for faster training
        epochs=fine_tune_epochs,
        validation_data=validation_generator,
        validation_steps=min(validation_generator.samples // 32, 50),  # Limit steps for faster training
        callbacks=[
            tf.keras.callbacks.EarlyStopping(monitor='val_accuracy', patience=2, restore_best_weights=True)
        ]
    )
    
    # Save the model
    model.save(MODEL_PATH)
    print(f"Model saved to {MODEL_PATH}")
    
    # Save class indices
    with open(CLASS_INDICES_PATH, 'w') as f:
        json.dump(train_generator.class_indices, f)
    print(f"Class indices saved to {CLASS_INDICES_PATH}")
    
    return model

def main():
    start_time = time.time()
    
    # Check if model already exists
    if os.path.exists(MODEL_PATH) and os.path.exists(CLASS_INDICES_PATH):
        print(f"Model {MODEL_PATH} and class indices {CLASS_INDICES_PATH} already exist.")
        print("To retrain, delete these files and run this script again.")
        return
    
    # Download and extract the dataset if needed
    if download_dataset():
        # Organize the dataset
        if organize_dataset():
            # Train the model
            train_dir = os.path.join(DATASET_DIR, 'train')
            validation_dir = os.path.join(DATASET_DIR, 'validation')
            train_model(train_dir, validation_dir)
            
            end_time = time.time()
            print(f"Total training time: {(end_time - start_time) / 60:.2f} minutes")
        else:
            print("Failed to organize dataset.")
    else:
        print("Failed to download dataset.")

if __name__ == "__main__":
    main()