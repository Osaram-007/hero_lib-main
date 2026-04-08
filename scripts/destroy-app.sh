#!/bin/bash

####################################################################
# destroy-app.sh
# Destroys ONLY the Cloud Run services for hero-app.
# This ensures that Artifact Registry, Secrets, and Service Accounts
# remain intact for future builds/triggers.
####################################################################

PROJECT_ID="hero-app-cicd-3409"
REGION="us-central1"

echo -e "\033[0;31m========================================="
echo -e "   HERO-APP (COMPUTE) DESTROY SCRIPT     "
echo -e "=========================================\033[0m"
echo ""
echo -e "\033[0;33mProject : $PROJECT_ID\033[0m"
echo -e "\033[0;33mRegion  : $REGION\033[0m"
echo ""
echo "This will ONLY delete the application services:"
echo "  - Cloud Run service: hero-app-frontend"
echo "  - Cloud Run service: hero-app-backend"
echo ""
echo "It will PRESERVE foundational infrastructure:"
echo "  - Artifact Registry (images stay safe)"
echo "  - Secret Manager (secrets stay safe)"
echo "  - Service Accounts (permissions stay safe)"
echo ""

if [[ "$1" != "--force" ]]; then
    read -p "Type [yes-destroy-app] to confirm: " confirm
    if [[ "$confirm" != "yes-destroy-app" ]]; then
        echo -e "\nAborted. Nothing was deleted."
        exit 0
    fi
fi

# Step 0: Check Auth
echo -e "\nStep 1/2 - Verifying gcloud authentication..."
account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
if [[ -z "$account" ]]; then
    echo "ERROR: Not authenticated. Run: gcloud auth application-default login"
    exit 1
fi
echo -e "Authenticated as: $account"

# Step 1: Delete Cloud Run services
echo -e "\nStep 2/2 - Deleting Cloud Run services..."

# Define services to delete
SERVICES=("hero-app-frontend" "hero-app-backend")

for svc in "${SERVICES[@]}"; do
    echo -e "\033[0;33mChecking status of $svc...\033[0m"
    if gcloud run services describe $svc --project=$PROJECT_ID --region=$REGION > /dev/null 2>&1; then
        echo -e "  Deleting: $svc..."
        gcloud run services delete $svc --project=$PROJECT_ID --region=$REGION --quiet
        echo -e "  \033[0;32mDeleted $svc.\033[0m"
    else
        echo -e "  \033[0;34m$svc already deleted or not found.\033[0m"
    fi
done

# Step 2: Summary
echo -e "\n\033[0;32m========================================="
echo -e "   CLEANUP COMPLETE                      "
echo -e "=========================================\033[0m"
echo ""
echo "The application compute layer has been removed."
echo "Foundational resources were NOT touched."
echo "Future build triggers can safely re-deploy."
echo ""
