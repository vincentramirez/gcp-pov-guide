resource "google_container_cluster" "k8s" {
  name               = "k8s"
  zone               = "${var.region}-a"
  initial_node_count = 1

  # this is going to be your project
  project = "${var.projectName}"

  # Don't worry about changing this unless something breaks, then let me know and we can address it then
  master_auth {
    username = "poc"
    password = "sixteendigitssssss"
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels {
      env = "sandbox"
    }

    tags = ["k8s", "poc"]
  }
}

# The following outputs allow authentication and connectivity to the GKE Cluster.
output "client_certificate" {
  value = "${google_container_cluster.k8s.master_auth.0.client_certificate}"
}

output "client_key" {
  value = "${google_container_cluster.k8s.master_auth.0.client_key}"
}

output "cluster_ca_certificate" {
  value = "${google_container_cluster.k8s.master_auth.0.cluster_ca_certificate}"
}
