output "frontend_url" {
  value       = google_cloud_run_v2_service.frontend.uri
  description = "The URL of the deployed Cloud Run Frontend service"
}

output "backend_url" {
  value       = google_cloud_run_v2_service.backend.uri
  description = "The URL of the deployed Cloud Run Backend service"
}

output "artifact_registry_repo" {
  value       = "${google_artifact_registry_repository.repo.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}"
  description = "The Artifact Registry repository URL"
}
