terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
  backend "gcs" {
    bucket = "terraform-state-hero-app-cicd-3409"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# 1. Enable Required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com"
  ])
  service = each.key
  disable_on_destroy = false
}

# 2. Artifact Registry
resource "google_artifact_registry_repository" "repo" {
  provider      = google-beta
  location      = var.region
  repository_id = "hero-app-repo"
  description   = "Docker repository for hero app"
  format        = "DOCKER"
  depends_on    = [google_project_service.apis]
}

# 3. Secret Manager
resource "google_secret_manager_secret" "app_secret" {
  secret_id = "hero-app-secret"
  replication {
    auto {}
  }
  depends_on = [google_project_service.apis]
}

resource "google_secret_manager_secret_version" "app_secret_placeholder" {
  secret      = google_secret_manager_secret.app_secret.id
  secret_data = "placeholder-value" # Update manually in GCP Console later with actual secrets
}

# 4. Custom Service Account for Cloud Run
resource "google_service_account" "cloudrun_sa" {
  account_id   = "hero-app-cloudrun-sa"
  display_name = "Cloud Run Service Account"
  depends_on   = [google_project_service.apis]
}

resource "google_secret_manager_secret_iam_member" "secret_access" {
  secret_id = google_secret_manager_secret.app_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloudrun_sa.email}"
}

# 5a. Cloud Run Service (Frontend)
resource "google_cloud_run_v2_service" "frontend" {
  provider   = google-beta
  name       = "hero-app-frontend"
  location   = var.region
  ingress    = "INGRESS_TRAFFIC_ALL"
  depends_on = [google_project_service.apis]

  template {
    service_account = google_service_account.cloudrun_sa.email
    containers {
      image = var.frontend_image
      
      ports {
        container_port = 3000
      }
    }
  }

  lifecycle {
    ignore_changes = [
      client,
      client_version
    ]
  }
}

data "google_iam_policy" "noauth_frontend" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth_frontend" {
  location    = google_cloud_run_v2_service.frontend.location
  project     = google_cloud_run_v2_service.frontend.project
  service     = google_cloud_run_v2_service.frontend.name
  policy_data = data.google_iam_policy.noauth_frontend.policy_data
}

# 5b. Cloud Run Service (Backend)
resource "google_cloud_run_v2_service" "backend" {
  provider   = google-beta
  name       = "hero-app-backend"
  location   = var.region
  ingress    = "INGRESS_TRAFFIC_ALL"
  depends_on = [google_project_service.apis]

  template {
    service_account = google_service_account.cloudrun_sa.email
    containers {
      image = var.backend_image
      
      ports {
        container_port = 5000
      }

      env {
        name = "APP_SECRET"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.app_secret.secret_id
            version = "latest"
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      client,
      client_version
    ]
  }
}

data "google_iam_policy" "noauth_backend" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth_backend" {
  location    = google_cloud_run_v2_service.backend.location
  project     = google_cloud_run_v2_service.backend.project
  service     = google_cloud_run_v2_service.backend.name
  policy_data = data.google_iam_policy.noauth_backend.policy_data
}


# 6. Cloud Build Service Account (Used for Cloud Build triggers)
resource "google_service_account" "cloudbuild_sa" {
  account_id   = "hero-app-cloudbuild-sa"
  display_name = "Cloud Build Pipeline Service Account"
  depends_on   = [google_project_service.apis]
}

resource "google_project_iam_member" "cloudbuild_roles" {
  for_each = toset([
    "roles/run.developer",
    "roles/artifactregistry.writer",
    "roles/artifactregistry.admin",
    "roles/storage.admin",
    "roles/secretmanager.secretAccessor",
    "roles/iam.serviceAccountUser",
    "roles/logging.logWriter"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.cloudbuild_sa.email}"
}

# 7. Cloud Build Triggers (Removed as they require manual GitHub App connection first)
# You must create the triggers manually in the GCP Console after connecting the GitHub repository.

# 7. Cloud Monitoring Uptime Check & Alert Policy
resource "google_monitoring_uptime_check_config" "https" {
  display_name = "Hero App Uptime Check"
  timeout      = "10s"
  period       = "60s"

  http_check {
    path = "/"
    port = "443"
    use_ssl = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = split("/", google_cloud_run_v2_service.default.uri)[2]
    }
  }
  depends_on = [google_project_service.apis]
}

resource "google_monitoring_alert_policy" "uptime_alert" {
  display_name = "Hero App Down Alert"
  combiner     = "OR"
  
  conditions {
    display_name = "Uptime check failed"
    condition_threshold {
      filter     = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.type=\"uptime_url\" AND metric.label.\"check_id\"=\"${google_monitoring_uptime_check_config.https.uptime_check_id}\""
      duration   = "300s" # Alert after 5 minutes of failure
      comparison = "COMPARISON_LT"
      threshold_value = 1
      
      aggregations {
        alignment_period   = "60s"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
      }
    }
  }
  depends_on = [google_project_service.apis]
}
