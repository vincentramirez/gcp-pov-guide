terraform {
  backend "gcs" {
    bucket = "deployment_state"
    prefix = "production"
  }
}

resource "google_storage_bucket" "deployment_state" {
  name     = "deployment_state"
  location = "US"
  project  = "${var.projectName}"
}
