#!/bin/bash
set -e

# Configuration
DEPLOY_DIR="deploy_env"
VENV_NAME="venv_deploy"
PORT=5001

# Cleanup previous deployment
echo "Cleaning up previous deployment..."
rm -rf $DEPLOY_DIR
mkdir -p $DEPLOY_DIR

# Build the package
echo "Building the package..."
python3 setup.py bdist_wheel

# Copy artifacts to deploy dir
cp dist/*.whl $DEPLOY_DIR/

# Create virtual environment
echo "Creating virtual environment in $DEPLOY_DIR/$VENV_NAME..."
cd $DEPLOY_DIR
python3 -m venv $VENV_NAME
source $VENV_NAME/bin/activate

# Install the package
echo "Installing package..."
pip install *.whl

# Start the application
echo "Starting application on port $PORT..."
export FLASK_APP=hero_lib.app.app
# Run in background
nohup flask run --host=0.0.0.0 --port=$PORT > app.log 2>&1 &
PID=$!
echo "Application started with PID $PID"

# Wait for app to start
sleep 5

# Run smoke tests
echo "Running smoke tests..."
cd ..
python3 scripts/smoke_test.py --url http://localhost:$PORT

# Cleanup (optional, comment out to keep running)
echo "Stopping application..."
kill $PID
