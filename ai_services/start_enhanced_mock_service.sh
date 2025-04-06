#!/bin/bash

# Create the enhanced nutrients database
echo "Creating enhanced nutrients database..."
python create_nutrients_db.py

# Start the mock food classification service
echo "Starting enhanced mock food classification service..."
python food_classification_service_mock.py