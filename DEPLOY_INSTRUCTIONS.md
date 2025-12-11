# Google Cloud Platform Deployment Guide

This project is configured to deploy to **Google Cloud Run** using GitHub Actions.

## Prerequisites

1.  **Google Cloud Project**: You need a GCP project.
2.  **APIs Enabled**: Enable the following APIs in your project:
    -   Cloud Run Admin API (`run.googleapis.com`)
    -   Cloud Build API (`cloudbuild.googleapis.com`)
    -   Container Registry API (`containerregistry.googleapis.com`) or Artifact Registry API
3.  **Service Account**: Create a Service Account with the following roles:
    -   `Cloud Run Admin`
    -   `Storage Admin` (for Container Registry)
    -   `Service Account User`
    -   `Cloud Build Editor`

## GitHub Secrets Configuration

Go to your GitHub repository -> **Settings** -> **Secrets and variables** -> **Actions** and add the following secrets:

-   `GCP_PROJECT_ID`: Your Google Cloud Project ID.
-   `GCP_CREDENTIALS`: The content of the JSON key file for the Service Account you created.

## Deployment

The deployment is automated via the `.github/workflows/deploy_gcp.yml` workflow.

-   **Trigger**: The workflow runs automatically on every push to the `main` branch.
-   **Manual Trigger**: You can also manually trigger it from the "Actions" tab in GitHub.

## Local Testing (Docker)

To run the container locally:

```bash
docker build -t hero-lib .
docker run -p 8080:8080 hero-lib
```

Access the app at `http://localhost:8080`.
