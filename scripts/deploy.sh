#!/bin/bash
set -e

echo "Starting deployment..."

# 1. Install System Dependencies (Robust Node.js 18)
echo "Setting up system dependencies..."
export DEBIAN_FRONTEND=noninteractive

# Update package list
sudo apt-get update

# Install Python tools if missing
if ! command -v pip3 &> /dev/null; then
    echo "Installing Python pip and venv..."
    sudo apt-get install -y python3-pip python3-venv
fi

# Install Node.js 18 from NodeSource (Avoids standard repo bloat)
if ! command -v node &> /dev/null || [[ $(node -v) != v18* ]]; then
    echo "Installing Node.js 18..."
    # Remove old versions to avoid conflicts
    sudo apt-get remove -y nodejs npm || true
    sudo apt-get autoremove -y || true
    
    # Add NodeSource repo and install
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    # Verify installation
    echo "Node.js version: $(node -v)"
    echo "NPM version: $(npm -v)"
fi

# Install PM2 globally if missing
if ! command -v pm2 &> /dev/null; then
    echo "Installing PM2..."
    sudo npm install -g pm2
fi

# 2. Setup Deployment Directory
APP_DIR="/opt/hero_lib"
echo "Setting up deployment directory at $APP_DIR..."
sudo mkdir -p $APP_DIR
sudo chown -R ubuntu:ubuntu $APP_DIR
cd $APP_DIR

# 3. Deploy Artifact
echo "Deploying artifact..."
# Check if artifact exists (it should be uploaded by gcloud scp/cp before this script runs)
if [ -f "deployment.tar.gz" ]; then
    # Backup previous version
    if [ -d 'current' ]; then
        echo "Backing up current version..."
        rm -rf previous
        mv current previous
    fi
    
    # Extract new version
    mkdir -p current
    tar -xzf deployment.tar.gz -C current/
    
    # Cleanup tarball
    rm deployment.tar.gz
else
    echo "Error: deployment.tar.gz not found!"
    exit 1
fi

cd current

# 4. Backend Setup
echo "Setting up Backend..."
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 5. Frontend Setup
echo "Setting up Frontend..."
if [ -d "new UI" ]; then
    cd "new UI"
    # Install dependencies (legacy-peer-deps for safety)
    npm install --legacy-peer-deps
    # Build Next.js app
    npm run build
    cd ..
else
    echo "Warning: 'new UI' directory not found. Skipping frontend build."
fi

# 6. Process Management (PM2)
echo "Reloading applications with PM2..."

# Stop existing processes to ensure clean slate (optional, reload is usually better but start/restart is safer for config changes)
pm2 delete hero_lib || true
pm2 delete libera-ui || true

# Start Backend
pm2 start hero_lib/app.py --name hero_lib --interpreter ./venv/bin/python3

# Start Frontend
if [ -d "new UI" ]; then
    cd "new UI"
    pm2 start npm --name "libera-ui" -- start
    cd ..
fi

pm2 save

echo "Waiting for services to stabilize..."
sleep 5
pm2 status

echo "Deployment completed successfully!"
