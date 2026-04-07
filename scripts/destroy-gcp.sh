#!/bin/bash

####################################################################
# destroy-gcp.sh
# Destroys all GCP resources managed by Terraform for hero-app.
####################################################################

PROJECT_ID="hero-app-cicd-3409"
REGION="us-central1"
TF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../terraform" && pwd)"

echo -e "\033[0;31m========================================="
echo -e "   GCP INFRASTRUCTURE DESTROY SCRIPT     "
echo -e "=========================================\033[0m"
echo ""
echo -e "\033[0;33mProject : $PROJECT_ID\033[0m"
echo -e "\033[0;33mRegion  : $REGION\033[0m"
echo ""
echo "This will PERMANENTLY delete:"
echo "  - Cloud Run services (frontend/backend)"
echo "  - Artifact Registry (hero-app-repo)"
echo "  - Secret Manager (hero-app-secret)"
echo "  - Monitoring checks & alert policies"
echo ""

if [[ "$1" != "--force" ]]; then
    read -p "Type [yes-destroy] to confirm: " confirm
    if [[ "$confirm" != "yes-destroy" ]]; then
        echo -e "\nAborted. Nothing was destroyed."
        exit 0
    fi
fi

# Step 0: Check Auth
echo -e "\nStep 0/3 - Verifying gcloud authentication..."
account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
if [[ -z "$account" ]]; then
    echo "ERROR: Not authenticated. Run: gcloud auth application-default login"
    exit 1
fi
echo -e "Authenticated as: $account"

# Step 1: Terraform
echo -e "\nStep 1/3 - Running terraform destroy..."
pushd "$TF_DIR" > /dev/null
terraform init -reconfigure > /dev/null

export TF_VAR_project_id=$PROJECT_ID
export TF_VAR_region=$REGION
export TF_VAR_backend_image="us-central1-docker.pkg.dev/$PROJECT_ID/hero-app-repo/hero-app-backend:latest"
export TF_VAR_frontend_image="us-central1-docker.pkg.dev/$PROJECT_ID/hero-app-repo/hero-app-frontend:latest"

terraform destroy -auto-approve
tf_exit=$?
popd > /dev/null

if [[ $tf_exit -ne 0 ]]; then
    echo -e "\nWARNING: terraform destroy failed with code $tf_exit."
else
    echo -e "\nTerraform destroy complete."
fi

# Step 2: Force Cleanup
echo -e "\nStep 2/3 - Force-checking for remaining Cloud Run services..."
remaining=$(gcloud run services list --project=$PROJECT_ID --region=$REGION --format="value(name)" | grep "hero-app")

if [[ ! -z "$remaining" ]]; then
    for svc in $remaining; do
        echo "  Force-deleting: $svc"
        gcloud run services delete $svc --project=$PROJECT_ID --region=$REGION --quiet
    done
else
    echo "  No hero-app services found. Clean!"
fi

# Step 3: Summary
echo -e "\n\033[0;32m========================================="
echo -e "   DESTROY COMPLETE                      "
echo -e "=========================================\033[0m"
echo ""
echo "Note: The Cloud Storage bucket [gs://terraform-state-$PROJECT_ID]"
echo "      was NOT deleted to preserve the terraform state file."
echo ""
