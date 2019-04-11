# I use templates to write systemd files dynamically, you will see these referenced in the specific *.tf files where the resource is being provisioned
data "template_file" "vault-systemd-client" {
  template = "${file("${var.localPath}/templates/systemd/vault.tpl")}"

  vars {
    userName = "${var.userName}"
  }
}

data "template_file" "consul-systemd-server" {
  template = "${file("${var.localPath}/templates/systemd/consul-server.tpl")}"

  vars {
    userName = "${var.userName}"
  }
}

data "template_file" "consul-systemd-client" {
  template = "${file("${var.localPath}/templates/systemd/consul-client.tpl")}"

  vars {
    userName = "${var.userName}"
  }
}

#You will need to set your GOOGLE_CREDENTIALS env variable
provider "google" {
  project = "${var.projectName}"
  region  = "${var.region}"
  zone    = "${var.region}-a"
}

#DATA SOURCES
data "google_compute_network" "east" {
  name     = "default" # leave this be for now
  provider = "google"
}

#FIREWALLS: VAULT & CONSUL (TCP)
resource "google_compute_firewall" "allow-tcp" {
  provider = "google"
  name     = "allow-tcp-east"
  network  = "${data.google_compute_network.east.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["8300", "8301", "8302", "8500", "8200", "8201"]
  }
}

#FIREWALLS: VAULT & CONSUL (UDP)
resource "google_compute_firewall" "allow-udp" {
  provider = "google"
  name     = "allow-udp-east"
  network  = "${data.google_compute_network.east.self_link}"

  allow {
    protocol = "udp"
    ports    = ["8301", "8302"]
  }
}

# FIREWALL FOR CASSANDRA DB
resource "google_compute_firewall" "allow-cassandra-access" {
  provider = "google"
  name = "db-east"
  network = "${data.google_compute_network.east.self_link}"

  allow {
    protocol = "tcp"
    ports = ["7000", "7001", "7199", "9042", "9160", "9142"]
  }
}

#FIREWALLS: HTTP/S ++ :8080
resource "google_compute_firewall" "allow-service-access" {
  provider = "google"
  name     = "http-east"
  network  = "${data.google_compute_network.east.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }
}

#FIREWALLS: SSH
resource "google_compute_firewall" "allow-ssh" {
  provider = "google"
  name     = "ssh-east"
  network  = "${data.google_compute_network.east.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
