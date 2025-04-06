#!/bin/bash

# Change to the ai_services directory
cd "$(dirname "$0")"

# Create the enhanced nutrients database
echo "Creating enhanced nutrients database..."
python create_nutrients_db.py

# Define the default port
DEFAULT_PORT=5002
PORT=$DEFAULT_PORT
MAX_PORT_ATTEMPTS=10

# Check if port is already in use and try to kill the process
if command -v lsof >/dev/null 2>&1; then
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "Port $PORT is already in use. Attempting to stop the existing process..."
        PID=$(lsof -Pi :$PORT -sTCP:LISTEN -t 2>/dev/null)
        if [ ! -z "$PID" ]; then
            echo "Killing process $PID that is using port $PORT..."
            kill -9 $PID 2>/dev/null
            sleep 2
            
            # Check if the port is still in use
            if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
                echo "Failed to kill the process. Port $PORT is still in use."
                
                # Try to find an available port
                echo "Looking for an available port..."
                for i in $(seq 1 $MAX_PORT_ATTEMPTS); do
                    NEW_PORT=$((PORT + i))
                    if ! lsof -Pi :$NEW_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
                        PORT=$NEW_PORT
                        echo "Found available port: $PORT"
                        break
                    fi
                    
                    if [ $i -eq $MAX_PORT_ATTEMPTS ]; then
                        echo "Could not find an available port after $MAX_PORT_ATTEMPTS attempts."
                        echo "Please manually identify and stop the process using port $DEFAULT_PORT, or specify a different port."
                        exit 1
                    fi
                done
            fi
        else
            echo "Could not identify the process using port $PORT."
        fi
    fi
else
    echo "lsof command not found. Cannot check for processes using port $PORT."
    echo "If the service fails to start, you may need to manually identify and stop the process using port $PORT."
fi

# Prepare dataset and train model if needed
echo "Preparing dataset and training model if needed..."

# Start the food classification service with the selected port
echo "Starting enhanced food classification service on port $PORT..."
FLASK_APP=food_classification_service FLASK_RUN_PORT=$PORT python -c "import food_classification_service as app; app.app.run(host='0.0.0.0', port=$PORT, debug=True)"