variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "Osaram-007"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "hero_lib-main"
}

variable "frontend_image" {
  description = "Docker image to deploy to Cloud Run Frontend (provided by Cloud Build)"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello" # Placeholder
}

variable "backend_image" {
  description = "Docker image to deploy to Cloud Run Backend (provided by Cloud Build)"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello" # Placeholder
}
