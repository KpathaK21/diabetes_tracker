#!/bin/bash

# Change to the ai_services directory
cd "$(dirname "$0")"

# Check if TensorFlow environment exists and activate it
if [ -d "tensorflow_env" ]; then
    echo "Activating TensorFlow environment..."
    source tensorflow_env/bin/activate
fi

# Create the nutrients database if it doesn't exist
if [ ! -f "food_nutrients_db.json" ]; then
    echo "Creating nutrients database..."
    python create_nutrients_db.py
fi

# Run the model training script
echo "Starting model training..."
echo "This may take some time depending on your hardware."
echo "The script will limit the number of images per class to make training faster."
echo "Training progress will be displayed below:"
echo "--------------------------------------------------------------"

python train_model.py

echo "--------------------------------------------------------------"
echo "Training completed!"
echo "The model has been saved as 'food_classification_model.h5'"
echo "The class indices have been saved as 'class_indices.json'"
echo ""
echo "You can now start the food classification service with:"
echo "./start_enhanced_service.sh"

# Deactivate the virtual environment if it was activated
if [ -d "tensorflow_env" ]; then
    deactivate 2>/dev/null || true
fi