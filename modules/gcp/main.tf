resource "random_string" "cloudbuild_name" {
  length  = 16
  special = false
  lower   = true
}

locals {
  cloudbuild_name = "${var.service_name}-image-builder-${random_string.cloudbuild_name.result}"
}

resource "google_cloudbuild_trigger" "build-trigger" {

  name     = local.cloudbuild_name
  filename = "cloudbuild.yaml"

  github {
    name  = split(".", split("/", var.github_repository_url)[length(split("/", var.github_repository_url)) - 1])[0]
    owner = var.github_credential_user_name
    push {
      branch = "^master$"
    }
  }

  substitutions = {
    _SERVICE_NAME            = var.service_name
    _REPOSITORY_NAME         = "gcr.io/${data.google_project.project.project_id}/${var.service_name}-image"
  }

}

resource "null_resource" "enable-cloudbuild-api" {
  provisioner "local-exec" {
    command = "gcloud services enable cloudbuild.googleapis.com"
  }
}

resource "null_resource" "create-cloud-build-sa" {
  depends_on = [
    null_resource.enable-cloudbuild-api
  ]
  provisioner "local-exec" {
    command = "gcloud beta services identity create --service cloudbuild.googleapis.com"
  }
}

resource "google_project_iam_member" "cloudbuild-service-account" {
  depends_on = [
    null_resource.create-cloud-build-sa
  ]
  project = data.google_project.project.project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}
