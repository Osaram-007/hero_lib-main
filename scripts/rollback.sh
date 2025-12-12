#!/bin/bash
set -e

echo "Starting rollback procedure..."

APP_DIR="/opt/hero_lib"

# Check if previous version exists
if [ -d "$APP_DIR/previous" ]; then
    echo "Found previous version. Restoring..."
    
    # 1. Stop current processes
    echo "Stopping current services..."
    pm2 stop hero_lib || true
    pm2 stop libera-ui || true
    
    # 2. Swap directories
    cd $APP_DIR
    
    # Move broken current to 'broken_rollover_<timestamp>' for debug
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    mv current "broken_$TIMESTAMP"
    
    # Restore previous
    mv previous current
    
    # 3. Restore Dependencies & Restart
    cd current
    
    # Re-link backend venv (usually stable, but good to be safe)
    if [ -f "requirements.txt" ]; then
        source venv/bin/activate
    fi
    
    echo "Restarting services with restored version..."
    
    # Restart Backend
    pm2 restart hero_lib --update-env
    
    # Restart Frontend
    if [ -d "new UI" ]; then
        cd "new UI"
        pm2 restart "libera-ui" --update-env
        cd ..
    fi

    echo "Rollback completed successfully. Services restored to previous version."
    echo "The broken deployment has been moved to: $APP_DIR/broken_$TIMESTAMP"
    
else
    echo "Error: No 'previous' directory found. Cannot rollback."
    echo "If this is a fresh install, there is no previous version to restore."
    exit 1
fi
