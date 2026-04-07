#!/usr/bin/env bash
####################################################################
# setup.sh  -  Full Bootstrap Script for Hero Lib Project (macOS)
#
# Run this ONCE on a brand-new Mac to:
#   1. Install all required tools (Homebrew, Git, gcloud, Terraform, Docker, Node.js, Python)
#   2. Clone the GitHub repository
#   3. Install Python and Node.js dependencies
#   4. Authenticate with Google Cloud
#   5. Enable required GCP APIs
#   6. Set up Terraform backend (GCS bucket)
#   7. Grant Cloud Build service account permissions
#   8. Run Terraform init + apply to create all infrastructure
#   9. Verify both Cloud Run services are live
#
# REQUIREMENTS before running:
#   - macOS 12+ (Monterey or newer recommended)
#   - Internet access
#   - A Google account with GCP access
#
# HOW TO RUN:
#   chmod +x scripts/setup.sh
#   ./scripts/setup.sh
#
# Or pass variables:
#   PROJECT_ID="my-project-123" GITHUB_REPO="user/repo" ./scripts/setup.sh
#
# To skip tool installation if already done:
#   SKIP_INSTALL=1 ./scripts/setup.sh
####################################################################

set -euo pipefail

# ── Default configuration ──────────────────────────────────────────
PROJECT_ID="${PROJECT_ID:-hero-app-cicd-3409}"
REGION="${REGION:-us-central1}"
GITHUB_REPO="${GITHUB_REPO:-Osaram-007/hero_lib-main}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"
REPO_DIR="${REPO_DIR:-$HOME/Projects/hero_lib-main}"
SKIP_INSTALL="${SKIP_INSTALL:-0}"

# ── Colours ────────────────────────────────────────────────────────
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GRAY='\033[0;90m'
WHITE='\033[0;37m'
NC='\033[0m' # No Colour

# ── Utility functions ──────────────────────────────────────────────

step() {
    echo ""
    echo -e "${GRAY}-----------------------------------------------------------${NC}"
    echo -e "  ${CYAN}STEP $1 - $2${NC}"
    echo -e "${GRAY}-----------------------------------------------------------${NC}"
}

ok()   { echo -e "  ${GREEN}[OK]${NC}   $*"; }
fail() { echo -e "  ${RED}[FAIL]${NC} $*"; exit 1; }
info() { echo -e "  ${YELLOW}[INFO]${NC} $*"; }

require_cmd() {
    local cmd="$1"
    local hint="${2:-}"
    if ! command -v "$cmd" &>/dev/null; then
        fail "'$cmd' is not available. ${hint}"
    fi
    ok "'$cmd' is available"
}

install_with_brew() {
    local formula="$1"
    local name="${2:-$formula}"
    if brew list --formula "$formula" &>/dev/null 2>&1 || brew list --cask "$formula" &>/dev/null 2>&1; then
        info "$name is already installed via Homebrew."
    else
        info "Installing $name via Homebrew..."
        brew install "$formula" || brew install --cask "$formula" || true
        ok "$name installed."
    fi
}

# ── Banner ─────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}==========================================================${NC}"
echo -e "${BLUE}   HERO LIB - FULL ENVIRONMENT SETUP SCRIPT (macOS)       ${NC}"
echo -e "${BLUE}==========================================================${NC}"
echo ""
echo -e "  ${WHITE}Project ID  : $PROJECT_ID${NC}"
echo -e "  ${WHITE}Region      : $REGION${NC}"
echo -e "  ${WHITE}GitHub Repo : $GITHUB_REPO${NC}"
echo -e "  ${WHITE}Local Dir   : $REPO_DIR${NC}"
echo ""

# ── STEP 1: Install Required Tools ────────────────────────────────
step "1" "Installing Required Tools"

if [[ "$SKIP_INSTALL" == "1" ]]; then
    info "Skipping tool installation (SKIP_INSTALL=1 was set)"
else

    # Homebrew
    if ! command -v brew &>/dev/null; then
        info "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Add brew to PATH for Apple Silicon Macs
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        ok "Homebrew installed."
    else
        ok "Homebrew is already installed."
        brew update --quiet || true
    fi

    # Git
    if ! command -v git &>/dev/null; then
        install_with_brew "git" "Git"
    else
        ok "Git is already installed."
    fi

    # Google Cloud SDK
    if ! command -v gcloud &>/dev/null; then
        info "Installing Google Cloud SDK..."
        brew install --cask google-cloud-sdk
        # Source gcloud into current shell
        if [[ -f "$(brew --prefix)/share/google-cloud-sdk/path.bash.inc" ]]; then
            source "$(brew --prefix)/share/google-cloud-sdk/path.bash.inc"
        fi
        ok "Google Cloud SDK installed."
    else
        ok "gcloud is already installed."
    fi

    # Terraform
    if ! command -v terraform &>/dev/null; then
        install_with_brew "hashicorp/tap/terraform" "Terraform"
    else
        ok "Terraform is already installed."
    fi

    # Docker Desktop
    if ! command -v docker &>/dev/null; then
        info "Installing Docker Desktop..."
        brew install --cask docker
        info "Docker Desktop installed. Open the Docker app once to complete setup."
    else
        ok "Docker is already installed."
    fi

    # Node.js (LTS via nvm or direct brew)
    if ! command -v node &>/dev/null; then
        install_with_brew "node@20" "Node.js LTS"
        brew link --overwrite node@20 || true
    else
        ok "Node.js is already installed."
    fi

    # Python 3
    if ! command -v python3 &>/dev/null; then
        install_with_brew "python@3.11" "Python 3.11"
    else
        ok "Python 3 is already installed."
    fi
fi

# Verify all critical tools
info "Verifying all tools..."
require_cmd "git"        "Run: brew install git"
require_cmd "gcloud"     "Run: brew install --cask google-cloud-sdk"
require_cmd "terraform"  "Run: brew install hashicorp/tap/terraform"
require_cmd "python3"    "Run: brew install python@3.11"
require_cmd "node"       "Run: brew install node@20"

ok "All required tools are present."

# ── STEP 2: Clone Repository ───────────────────────────────────────
step "2" "Cloning GitHub Repository"

if [[ -d "$REPO_DIR" ]]; then
    info "Directory already exists at $REPO_DIR"
    info "Pulling latest changes..."
    git -C "$REPO_DIR" pull origin "$GITHUB_BRANCH"
else
    info "Cloning https://github.com/$GITHUB_REPO ..."
    git clone "https://github.com/${GITHUB_REPO}.git" "$REPO_DIR"
    ok "Repository cloned to $REPO_DIR"
fi

# ── STEP 3: Install Python Dependencies ───────────────────────────
step "3" "Installing Python Backend Dependencies"

pushd "$REPO_DIR" > /dev/null
python3 -m pip install --upgrade pip --quiet
python3 -m pip install -r requirements.txt
ok "Python packages installed."
popd > /dev/null

# ── STEP 4: Install Node.js Dependencies ──────────────────────────
step "4" "Installing Node.js Frontend Dependencies"

UI_DIR="$REPO_DIR/new UI"
if [[ -d "$UI_DIR" ]]; then
    pushd "$UI_DIR" > /dev/null
    npm install --legacy-peer-deps
    ok "Node.js packages installed."
    popd > /dev/null
else
    info "UI directory not found at '$UI_DIR', skipping npm install."
fi

# ── STEP 5: Authenticate with Google Cloud ────────────────────────
step "5" "Google Cloud Authentication"

ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>&1 || true)

if [[ -z "$ACTIVE_ACCOUNT" ]]; then
    info "No active gcloud account found. Opening browser for login..."
    gcloud auth login
    gcloud auth application-default login
else
    ok "Already authenticated as: $ACTIVE_ACCOUNT"
fi

# Set project
gcloud config set project "$PROJECT_ID"
ok "Active GCP project set to: $PROJECT_ID"

# ── STEP 6: Enable Required GCP APIs ──────────────────────────────
step "6" "Enabling Required GCP APIs"

APIS=(
    "cloudresourcemanager.googleapis.com"
    "iam.googleapis.com"
    "cloudbuild.googleapis.com"
    "artifactregistry.googleapis.com"
    "run.googleapis.com"
    "secretmanager.googleapis.com"
    "monitoring.googleapis.com"
    "logging.googleapis.com"
    "storage.googleapis.com"
)

info "Enabling APIs (this can take 1-2 minutes)..."
for api in "${APIS[@]}"; do
    info "  Enabling $api"
    gcloud services enable "$api" --project="$PROJECT_ID" --quiet 2>&1 || true
done
ok "All APIs enabled."

# ── STEP 7: Create Terraform State Bucket ─────────────────────────
step "7" "Setting Up Terraform State Backend (GCS Bucket)"

BUCKET_NAME="terraform-state-${PROJECT_ID}"

if gcloud storage buckets describe "gs://${BUCKET_NAME}" --project="$PROJECT_ID" &>/dev/null 2>&1; then
    ok "Terraform state bucket already exists: gs://$BUCKET_NAME"
else
    info "Creating GCS bucket: gs://$BUCKET_NAME"
    gcloud storage buckets create "gs://${BUCKET_NAME}" \
        --project="$PROJECT_ID" \
        --location="$REGION" \
        --uniform-bucket-level-access
    ok "Bucket created: gs://$BUCKET_NAME"
fi

# ── STEP 8: Grant Cloud Build Service Account Permissions ─────────
step "8" "Granting Cloud Build Service Account Permissions"

PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
CB_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

info "Cloud Build SA: $CB_SA"

ROLES=(
    "roles/run.developer"
    "roles/iam.serviceAccountUser"
    "roles/artifactregistry.admin"
    "roles/storage.admin"
    "roles/secretmanager.secretAccessor"
    "roles/logging.logWriter"
)

for role in "${ROLES[@]}"; do
    info "  Granting $role"
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:${CB_SA}" \
        --role="$role" \
        --quiet 2>&1 | tail -1 || true
done
ok "Cloud Build permissions granted."

# ── STEP 9: Terraform Init and Apply ──────────────────────────────
step "9" "Running Terraform Init and Apply"

pushd "$REPO_DIR/terraform" > /dev/null

info "Running terraform init..."
terraform init -reconfigure || { fail "terraform init failed."; popd > /dev/null; exit 1; }

info "Running terraform plan..."
export TF_VAR_project_id="$PROJECT_ID"
export TF_VAR_region="$REGION"
export TF_VAR_backend_image="us-${REGION}-docker.pkg.dev/${PROJECT_ID}/hero-app-repo/hero-app-backend:latest"
export TF_VAR_frontend_image="us-${REGION}-docker.pkg.dev/${PROJECT_ID}/hero-app-repo/hero-app-frontend:latest"

terraform plan -out=tfplan

info "Running terraform apply..."
terraform apply -auto-approve tfplan || { fail "terraform apply failed. Check the output above."; popd > /dev/null; exit 1; }

popd > /dev/null
ok "Infrastructure deployed via Terraform."

# ── STEP 10: Connect GitHub to Cloud Build (Manual Step Notice) ────
step "10" "Cloud Build GitHub Connection (Manual Step)"

echo ""
echo -e "  ${YELLOW}ACTION REQUIRED: Connect your GitHub repository to Cloud Build manually.${NC}"
echo ""
echo -e "  ${WHITE}1. Open: https://console.cloud.google.com/cloud-build/triggers/connect${NC}"
echo -e "  ${WHITE}   Project: $PROJECT_ID${NC}"
echo ""
echo -e "  ${WHITE}2. Choose GitHub and authorize Google Cloud Build${NC}"
echo ""
echo -e "  ${WHITE}3. Create a trigger with these settings:${NC}"
echo -e "       ${CYAN}- Repo       : $GITHUB_REPO${NC}"
echo -e "       ${CYAN}- Branch     : ^${GITHUB_BRANCH}\$${NC}"
echo -e "       ${CYAN}- Config file: cloudbuild.yaml${NC}"
echo -e "       ${CYAN}- SA         : hero-app-cloudbuild-sa@${PROJECT_ID}.iam.gserviceaccount.com${NC}"
echo ""
echo -e "  ${GREEN}After this, every git push to '${GITHUB_BRANCH}' will auto-deploy.${NC}"
echo ""

# ── STEP 11: Verify Deployments ───────────────────────────────────
step "11" "Verifying Cloud Run Services"

info "Waiting 10 seconds for services to be ready..."
sleep 10

gcloud run services list \
    --project="$PROJECT_ID" \
    --region="$REGION" \
    --format="table(name,URL,LAST_DEPLOYED_BY)"

ok "Cloud Run services listed above."

# ── Final Summary ─────────────────────────────────────────────────
echo ""
echo -e "${GREEN}==========================================================${NC}"
echo -e "${GREEN}   SETUP COMPLETE                                          ${NC}"
echo -e "${GREEN}==========================================================${NC}"
echo ""
echo -e "  ${WHITE}Local repo  : $REPO_DIR${NC}"
echo -e "  ${WHITE}GCP project : $PROJECT_ID${NC}"
echo -e "  ${WHITE}Region      : $REGION${NC}"
echo ""
echo -e "  ${YELLOW}NEXT STEPS:${NC}"
echo    "  1. Connect GitHub to Cloud Build (see Step 10 above)"
echo    "  2. Push a commit to trigger the CI/CD pipeline:"
echo ""
echo -e "       ${CYAN}cd $REPO_DIR${NC}"
echo -e "       ${CYAN}git commit --allow-empty -m 'ci: trigger first build'${NC}"
echo -e "       ${CYAN}git push origin $GITHUB_BRANCH${NC}"
echo ""
echo -e "  ${YELLOW}3. Watch the build at:${NC}"
echo -e "     ${CYAN}https://console.cloud.google.com/cloud-build/builds?project=$PROJECT_ID${NC}"
echo ""
