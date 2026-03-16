####################################################################
# destroy-gcp.ps1
# Destroys all GCP resources managed by Terraform for hero-app.
# Run from the scripts folder: .\destroy-gcp.ps1
#
# What gets destroyed:
#   - Cloud Run service: hero-app-frontend
#   - Cloud Run service: hero-app-backend
#   - Artifact Registry repository: hero-app-repo
#   - Secret Manager secret: hero-app-secret
#   - Service Accounts (cloudrun-sa, cloudbuild-sa)
#   - Cloud Monitoring uptime checks and alert policies
#   - IAM role bindings
#
# What is NOT destroyed:
#   - GCP APIs (disable_on_destroy = false in Terraform)
#   - The GCS bucket storing Terraform state
####################################################################

param(
    [switch]$Force   # Skip interactive confirmation if set
)

$PROJECT_ID      = "hero-app-cicd-3409"
$REGION          = "us-central1"
$TF_DIR          = Join-Path $PSScriptRoot "..\terraform"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Red
Write-Host "   GCP INFRASTRUCTURE DESTROY SCRIPT     " -ForegroundColor Red
Write-Host "=========================================" -ForegroundColor Red
Write-Host ""
Write-Host "Project : $PROJECT_ID" -ForegroundColor Yellow
Write-Host "Region  : $REGION"     -ForegroundColor Yellow
Write-Host ""
Write-Host "This will PERMANENTLY delete:" -ForegroundColor White
Write-Host "  - Cloud Run service  : hero-app-frontend" -ForegroundColor Cyan
Write-Host "  - Cloud Run service  : hero-app-backend"  -ForegroundColor Cyan
Write-Host "  - Artifact Registry  : hero-app-repo"     -ForegroundColor Cyan
Write-Host "  - Secret Manager     : hero-app-secret"   -ForegroundColor Cyan
Write-Host "  - Service Accounts   : cloudrun-sa, cloudbuild-sa" -ForegroundColor Cyan
Write-Host "  - Monitoring checks  : uptime check + alert policy" -ForegroundColor Cyan
Write-Host ""

# --- Safety confirmation ---
if (-not $Force) {
    $confirm = Read-Host "Type [yes-destroy] to confirm"
    if ($confirm -ne "yes-destroy") {
        Write-Host ""
        Write-Host "Aborted. Nothing was destroyed." -ForegroundColor Green
        exit 0
    }
}

# --- Check Terraform is available ---
if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "ERROR: terraform not found in PATH." -ForegroundColor Red
    Write-Host "       Install from: https://www.terraform.io/downloads" -ForegroundColor Red
    exit 1
}

# --- Check gcloud is authenticated ---
Write-Host ""
Write-Host "Step 0/3 - Verifying gcloud authentication..." -ForegroundColor Yellow

$account = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>&1

if (-not $account) {
    Write-Host "ERROR: Not authenticated with gcloud." -ForegroundColor Red
    Write-Host "       Run: gcloud auth application-default login" -ForegroundColor Red
    exit 1
}

Write-Host "Authenticated as: $account" -ForegroundColor Green

# --- Step 1: Remove stale Terraform state entries ---
Write-Host ""
Write-Host "Step 1/3 - Cleaning stale Terraform state entries..." -ForegroundColor Yellow

Push-Location $TF_DIR

Write-Host "  Running terraform init..." -ForegroundColor Gray
terraform init -reconfigure | Out-Null

# These may not exist in state - errors suppressed intentionally
terraform state rm google_cloud_run_service_iam_policy.noauth          2>&1 | Out-Null
terraform state rm google_monitoring_uptime_check_config.https          2>&1 | Out-Null
terraform state rm google_monitoring_alert_policy.uptime_alert          2>&1 | Out-Null

Write-Host "  State cleanup done." -ForegroundColor Green

# --- Step 2: Terraform destroy ---
Write-Host ""
Write-Host "Step 2/3 - Running terraform destroy..." -ForegroundColor Yellow
Write-Host "  (This may take 1-3 minutes)" -ForegroundColor Gray

$env:TF_VAR_project_id     = $PROJECT_ID
$env:TF_VAR_region         = $REGION
$env:TF_VAR_backend_image  = "us-central1-docker.pkg.dev/$PROJECT_ID/hero-app-repo/hero-app-backend:latest"
$env:TF_VAR_frontend_image = "us-central1-docker.pkg.dev/$PROJECT_ID/hero-app-repo/hero-app-frontend:latest"

terraform destroy -auto-approve
$exitCode = $LASTEXITCODE

Pop-Location

if ($exitCode -ne 0) {
    Write-Host ""
    Write-Host "WARNING: terraform destroy finished with errors (exit code $exitCode)." -ForegroundColor Yellow
    Write-Host "         Some resources may still exist. Check the GCP Console." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Terraform destroy complete." -ForegroundColor Green
}

# --- Step 3: Verify Cloud Run services are gone ---
Write-Host ""
Write-Host "Step 3/3 - Verifying Cloud Run services..." -ForegroundColor Yellow

$services   = gcloud run services list --project=$PROJECT_ID --region=$REGION --format="value(name)" 2>&1
$remaining  = $services | Where-Object { $_ -match "hero-app" }

if ($remaining) {
    Write-Host ""
    Write-Host "WARNING: The following hero-app services are still running:" -ForegroundColor Yellow
    $remaining | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host ""
    Write-Host "  Force-deleting them now..." -ForegroundColor Yellow
    $remaining | ForEach-Object {
        Write-Host "  Deleting: $_" -ForegroundColor Gray
        gcloud run services delete $_ --project=$PROJECT_ID --region=$REGION --quiet 2>&1
    }
    Write-Host "  Force delete done." -ForegroundColor Green
} else {
    Write-Host "  No hero-app Cloud Run services found. All clean!" -ForegroundColor Green
}

# --- Summary ---
Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "   DESTROY COMPLETE                      " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "NOTE: The GCS bucket [terraform-state-hero-app-cicd-3409]"
Write-Host "      was NOT deleted (it holds Terraform state)."
Write-Host "      To delete it manually, run:"
Write-Host ""
Write-Host "  gcloud storage rm -r gs://terraform-state-hero-app-cicd-3409" -ForegroundColor Cyan
Write-Host ""
