#!/bin/bash

# Create the enhanced nutrients database
echo "Creating enhanced nutrients database..."
python create_nutrients_db.py

# Start the food classification service
echo "Starting enhanced food classification service..."
python food_classification_service.py