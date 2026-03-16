####################################################################
# setup.ps1  -  Full Bootstrap Script for Hero Lib Project
#
# Run this ONCE on a brand-new Windows machine to:
#   1. Install all required tools (Winget, Chocolatey, Scoop fallbacks)
#   2. Clone the GitHub repository
#   3. Authenticate with Google Cloud
#   4. Create the GCP project and enable billing
#   5. Set up Terraform backend (GCS bucket)
#   6. Bootstrap the CI/CD pipeline (Cloud Build trigger)
#   7. Run first Terraform init + apply to create all infrastructure
#   8. Verify both Cloud Run services are live
#
# REQUIREMENTS before running:
#   - Windows 10/11 with PowerShell 5.1+
#   - Internet access
#   - A Google account with GCP access
#   - Git already installed (or script will install it)
#
# HOW TO RUN:
#   Set-ExecutionPolicy Bypass -Scope Process -Force
#   .\setup.ps1
#
# Or pass variables directly:
#   .\setup.ps1 -ProjectId "my-project-123" -GitHubRepo "user/repo"
####################################################################

param(
    [string]$ProjectId    = "hero-app-cicd-3409",
    [string]$Region       = "us-central1",
    [string]$GitHubRepo   = "Osaram-007/hero_lib-main",
    [string]$GitHubBranch = "main",
    [string]$RepoDir      = "$HOME\Projects\hero_lib-main",
    [switch]$SkipInstall  # Skip tool installation if already done
)

# ── Utility functions ──────────────────────────────────────────────

function Write-Step {
    param([string]$Number, [string]$Title)
    Write-Host ""
    Write-Host "-----------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  STEP $Number - $Title" -ForegroundColor Cyan
    Write-Host "-----------------------------------------------------------" -ForegroundColor DarkGray
}

function Write-OK   { Write-Host "  [OK] $args" -ForegroundColor Green }
function Write-FAIL { Write-Host "  [FAIL] $args" -ForegroundColor Red }
function Write-INFO { Write-Host "  [INFO] $args" -ForegroundColor Yellow }

function Assert-Command {
    param([string]$Cmd, [string]$InstallHint)
    if (-not (Get-Command $Cmd -ErrorAction SilentlyContinue)) {
        Write-FAIL "$Cmd is not available. $InstallHint"
        exit 1
    }
    Write-OK "$Cmd is available"
}

function Install-WithWinget {
    param([string]$PackageId, [string]$Name)
    Write-INFO "Installing $Name via winget..."
    winget install --id $PackageId --silent --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-INFO "winget install returned non-zero. May already be installed."
    } else {
        Write-OK "$Name installed."
    }
}

# ── Banner ─────────────────────────────────────────────────────────

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Blue
Write-Host "   HERO LIB - FULL ENVIRONMENT SETUP SCRIPT               " -ForegroundColor Blue
Write-Host "==========================================================" -ForegroundColor Blue
Write-Host ""
Write-Host "  Project ID  : $ProjectId"    -ForegroundColor White
Write-Host "  Region      : $Region"       -ForegroundColor White
Write-Host "  GitHub Repo : $GitHubRepo"   -ForegroundColor White
Write-Host "  Local Dir   : $RepoDir"      -ForegroundColor White
Write-Host ""

# ── STEP 1: Install Required Tools ────────────────────────────────
Write-Step "1" "Installing Required Tools"

if ($SkipInstall) {
    Write-INFO "Skipping tool installation (-SkipInstall was passed)"
} else {

    # Check winget
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-FAIL "winget not found. Install it from: https://aka.ms/getwinget"
        Write-INFO "Or install tools manually, then re-run with -SkipInstall"
        exit 1
    }

    # Git
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Install-WithWinget "Git.Git" "Git"
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine")
    }

    # Google Cloud SDK
    if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
        Install-WithWinget "Google.CloudSDK" "Google Cloud SDK"
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + $env:PATH
    }

    # Terraform
    if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
        Install-WithWinget "Hashicorp.Terraform" "Terraform"
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + $env:PATH
    }

    # Docker Desktop
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Install-WithWinget "Docker.DockerDesktop" "Docker Desktop"
        Write-INFO "Docker Desktop was installed. You may need to restart Windows once before Docker works."
    }

    # Node.js
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Install-WithWinget "OpenJS.NodeJS.LTS" "Node.js LTS"
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + $env:PATH
    }

    # Python 3.11
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        Install-WithWinget "Python.Python.3.11" "Python 3.11"
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + $env:PATH
    }
}

# Verify all critical tools
Write-INFO "Verifying all tools..."
Assert-Command "git"       "Run: winget install Git.Git"
Assert-Command "gcloud"    "Run: winget install Google.CloudSDK"
Assert-Command "terraform" "Run: winget install Hashicorp.Terraform"
Assert-Command "python"    "Run: winget install Python.Python.3.11"
Assert-Command "node"      "Run: winget install OpenJS.NodeJS.LTS"

Write-OK "All required tools are present."

# ── STEP 2: Clone Repository ───────────────────────────────────────
Write-Step "2" "Cloning GitHub Repository"

if (Test-Path $RepoDir) {
    Write-INFO "Directory already exists at $RepoDir"
    Write-INFO "Pulling latest changes..."
    Push-Location $RepoDir
    git pull origin $GitHubBranch
    Pop-Location
} else {
    Write-INFO "Cloning https://github.com/$GitHubRepo ..."
    git clone "https://github.com/$GitHubRepo.git" $RepoDir
    if ($LASTEXITCODE -ne 0) {
        Write-FAIL "git clone failed."
        exit 1
    }
    Write-OK "Repository cloned to $RepoDir"
}

# ── STEP 3: Install Python Dependencies ───────────────────────────
Write-Step "3" "Installing Python Backend Dependencies"

Push-Location $RepoDir
python -m pip install --upgrade pip | Out-Null
python -m pip install -r requirements.txt
Write-OK "Python packages installed."
Pop-Location

# ── STEP 4: Install Node.js Dependencies ──────────────────────────
Write-Step "4" "Installing Node.js Frontend Dependencies"

Push-Location "$RepoDir\new UI"
npm install --legacy-peer-deps
if ($LASTEXITCODE -ne 0) {
    Write-FAIL "npm install failed."
    exit 1
}
Write-OK "Node.js packages installed."
Pop-Location

# ── STEP 5: Authenticate with Google Cloud ────────────────────────
Write-Step "5" "Google Cloud Authentication"

$activeAccount = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>&1

if (-not $activeAccount) {
    Write-INFO "No active gcloud account found. Opening browser for login..."
    gcloud auth login
    gcloud auth application-default login
} else {
    Write-OK "Already authenticated as: $activeAccount"
}

# Set project
gcloud config set project $ProjectId
Write-OK "Active GCP project set to: $ProjectId"

# ── STEP 6: Enable Required GCP APIs ──────────────────────────────
Write-Step "6" "Enabling Required GCP APIs"

$APIS = @(
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "storage.googleapis.com"
)

Write-INFO "Enabling APIs (this can take 1-2 minutes)..."
foreach ($api in $APIS) {
    Write-INFO "  Enabling $api"
    gcloud services enable $api --project=$ProjectId 2>&1 | Out-Null
}
Write-OK "All APIs enabled."

# ── STEP 7: Create Terraform State Bucket ─────────────────────────
Write-Step "7" "Setting Up Terraform State Backend (GCS Bucket)"

$BUCKET_NAME = "terraform-state-$ProjectId"

$bucketExists = gcloud storage buckets list --project=$ProjectId --format="value(name)" 2>&1 | Where-Object { $_ -eq $BUCKET_NAME }

if ($bucketExists) {
    Write-OK "Terraform state bucket already exists: gs://$BUCKET_NAME"
} else {
    Write-INFO "Creating GCS bucket: gs://$BUCKET_NAME"
    gcloud storage buckets create "gs://$BUCKET_NAME" `
        --project=$ProjectId `
        --location=$Region `
        --uniform-bucket-level-access
    if ($LASTEXITCODE -ne 0) {
        Write-FAIL "Failed to create GCS bucket."
        exit 1
    }
    Write-OK "Bucket created: gs://$BUCKET_NAME"
}

# ── STEP 8: Grant Cloud Build Service Account Permissions ─────────
Write-Step "8" "Granting Cloud Build Service Account Permissions"

$PROJECT_NUMBER = gcloud projects describe $ProjectId --format="value(projectNumber)"
$CB_SA = "$PROJECT_NUMBER@cloudbuild.gserviceaccount.com"

Write-INFO "Cloud Build SA: $CB_SA"

$ROLES = @(
    "roles/run.developer",
    "roles/iam.serviceAccountUser",
    "roles/artifactregistry.admin",
    "roles/storage.admin",
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter"
)

foreach ($role in $ROLES) {
    Write-INFO "  Granting $role"
    gcloud projects add-iam-policy-binding $ProjectId `
        --member="serviceAccount:$CB_SA" `
        --role=$role `
        --quiet 2>&1 | Out-Null
}
Write-OK "Cloud Build permissions granted."

# ── STEP 9: Terraform Init and Apply ──────────────────────────────
Write-Step "9" "Running Terraform Init and Apply"

Push-Location "$RepoDir\terraform"

Write-INFO "Running terraform init..."
terraform init -reconfigure
if ($LASTEXITCODE -ne 0) {
    Write-FAIL "terraform init failed."
    Pop-Location
    exit 1
}

Write-INFO "Running terraform plan..."
$env:TF_VAR_project_id     = $ProjectId
$env:TF_VAR_region         = $Region
$env:TF_VAR_backend_image  = "us-$Region-docker.pkg.dev/$ProjectId/hero-app-repo/hero-app-backend:latest"
$env:TF_VAR_frontend_image = "us-$Region-docker.pkg.dev/$ProjectId/hero-app-repo/hero-app-frontend:latest"

terraform plan -out=tfplan

Write-INFO "Running terraform apply..."
terraform apply -auto-approve tfplan
if ($LASTEXITCODE -ne 0) {
    Write-FAIL "terraform apply failed. Check the output above."
    Pop-Location
    exit 1
}

Pop-Location
Write-OK "Infrastructure deployed via Terraform."

# ── STEP 10: Connect GitHub to Cloud Build (Manual Step Notice) ────
Write-Step "10" "Cloud Build GitHub Connection (Manual Step)"

Write-Host ""
Write-Host "  ACTION REQUIRED: Connect your GitHub repository to Cloud Build manually." -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Open: https://console.cloud.google.com/cloud-build/triggers/connect" -ForegroundColor White
Write-Host "     Project: $ProjectId"                                                   -ForegroundColor White
Write-Host ""
Write-Host "  2. Choose GitHub and authorize Google Cloud Build"                         -ForegroundColor White
Write-Host ""
Write-Host "  3. Create a trigger with these settings:"                                  -ForegroundColor White
Write-Host "       - Repo       : $GitHubRepo"                                          -ForegroundColor Cyan
Write-Host "       - Branch     : ^$GitHubBranch$"                                      -ForegroundColor Cyan
Write-Host "       - Config file: cloudbuild.yaml"                                      -ForegroundColor Cyan
Write-Host "       - SA         : hero-app-cloudbuild-sa@$ProjectId.iam.gserviceaccount.com" -ForegroundColor Cyan
Write-Host ""
Write-Host "  After this, every git push to '$GitHubBranch' will auto-deploy."          -ForegroundColor Green
Write-Host ""

# ── STEP 11: Verify Deployments ───────────────────────────────────
Write-Step "11" "Verifying Cloud Run Services"

Write-INFO "Waiting 10 seconds for services to be ready..."
Start-Sleep -Seconds 10

$services = gcloud run services list --project=$ProjectId --region=$Region --format="table(name,URL,LAST_DEPLOYED_BY)"
Write-Host $services
Write-OK "Cloud Run services listed above."

# ── Final Summary ─────────────────────────────────────────────────
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "   SETUP COMPLETE                                          " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Local repo  : $RepoDir"           -ForegroundColor White
Write-Host "  GCP project : $ProjectId"         -ForegroundColor White
Write-Host "  Region      : $Region"            -ForegroundColor White
Write-Host ""
Write-Host "  NEXT STEPS:"                       -ForegroundColor Yellow
Write-Host "  1. Connect GitHub to Cloud Build (see Step 10 above)"
Write-Host "  2. Push a commit to trigger the CI/CD pipeline:"
Write-Host ""
Write-Host "       cd $RepoDir"                  -ForegroundColor Cyan
Write-Host "       git commit --allow-empty -m 'ci: trigger first build'" -ForegroundColor Cyan
Write-Host "       git push origin $GitHubBranch" -ForegroundColor Cyan
Write-Host ""
Write-Host "  3. Watch the build at:"            -ForegroundColor Yellow
Write-Host "     https://console.cloud.google.com/cloud-build/builds?project=$ProjectId" -ForegroundColor Cyan
Write-Host ""
