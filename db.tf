resource "google_compute_instance" "containerized" {
  count        = 1
  name         = "containerized"
  machine_type = "${var.machineTypes["vault-client"]}"
  zone         = "${var.region}-a"
  tags         = ["macys-cluster-dc1", "docker", "http-server"]

  metadata {
    sshKeys = "${var.userName}:${file("/Users/${var.userName}/.ssh/id_rsa.pub")}"
  }

  boot_disk {
    initialize_params {
      image = "${var.imageSpec}"
    }
  }

  service_account {
    email  = "${var.serviceAccount["email"]}"
    scopes = "${list(var.serviceAccount["scopes"])}"
  }

  network_interface {
    network = "default"

    access_config {
      // Include this section to give the VM an external ip address
    }
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "${var.userName}"
      private_key = "${file("/Users/${var.userName}/.ssh/id_rsa")}"
    }

    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install unzip apt-transport-https ca-certificates curl gnupg2 software-properties-common",
      "sudo apt install openjdk-8-jre -y",
      "sudo apt-get install python",
      "echo deb http://www.apache.org/dist/cassandra/debian 311x main | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list",
      "curl https://www.apache.org/dist/cassandra/KEYS | sudo apt-key add -",
      "sudo apt-get -y update",
      "sudo apt-get install cassandra",
      "mkdir /home/${var.userName}/consul.d",
      "mkdir /home/${var.userName}/consul.d/data",
    ]
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "${var.userName}"
      private_key = "${file("/Users/${var.userName}/.ssh/id_rsa")}"
    }

    source      = "${var.localPath}/binaries/consul_${var.consulVersion}_linux_amd64.zip"
    destination = "/home/${var.userName}/consul_${var.consulVersion}_linux_amd64.zip"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "${var.userName}"
      private_key = "${file("/Users/${var.userName}/.ssh/id_rsa")}"
    }

    content = <<JSON
    {
      ${jsonencode("server")}: false,
      ${jsonencode("node_name")}: ${jsonencode("containerized")},
      ${jsonencode("datacenter")}: ${jsonencode("dc1")},
      ${jsonencode("data_dir")}: ${jsonencode("/home/${var.userName}/consul.d/data")},
      ${jsonencode("bind_addr")}: ${jsonencode("0.0.0.0")},
      ${jsonencode("client_addr")}: ${jsonencode("0.0.0.0")},
      ${jsonencode("advertise_addr")}: ${jsonencode("${self.network_interface.0.access_config.0.nat_ip}")},
      ${jsonencode("retry_join")}: ${jsonencode("${list("provider=gce project_name=${var.userName}-test tag_value=macys-cluster-dc1")}")},
      ${jsonencode("log_level")}: ${jsonencode("DEBUG")},
      ${jsonencode("enable_syslog")}: true,
      ${jsonencode("acl_enforce_version_8")}: false
      }
      JSON

    destination = "/home/${var.userName}/consul.d/client.json"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "${var.userName}"
      private_key = "${file("/Users/${var.userName}/.ssh/id_rsa")}"
    }

    content     = "${data.template_file.consul-systemd-client.rendered}"
    destination = "/home/${var.userName}/consul-client.service"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "${var.userName}"
      private_key = "${file("/Users/${var.userName}/.ssh/id_rsa")}"
    }

    content = <<JSON
    {
      ${jsonencode("service")}: {
        ${jsonencode("id")}: ${jsonencode("cassandra-1")},
        ${jsonencode("name")}: ${jsonencode("cassandra")},
        ${jsonencode("port")}: 9042
      }
    }
    JSON

    destination = "/home/${var.userName}/consul.d/cassandra.json"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "${var.userName}"
      private_key = "${file("/Users/${var.userName}/.ssh/id_rsa")}"
    }

    inline = [
      "unzip /home/${var.userName}/consul_${var.consulVersion}_linux_amd64.zip",
      "sudo mv /home/${var.userName}/consul /bin/",
      "rm /home/${var.userName}/consul_${var.consulVersion}_linux_amd64.zip",
      "sudo mv /home/${var.userName}/*.service /etc/systemd/system/",
      "sudo systemctl start consul-client",
    ]
  }
}
