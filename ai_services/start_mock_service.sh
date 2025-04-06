#!/bin/bash

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Install requirements
pip install flask pillow

# Start the Flask application
python food_classification_service_mock.py