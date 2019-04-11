// 3 Vault Clients
resource "google_compute_instance" "vault-client" {
  depends_on   = ["google_compute_instance.consul-server"]
  count        = "${var.counts["vault-client"]}"
  name         = "vault-client-${count.index}"
  machine_type = "${var.machineTypes["vault-client"]}"
  zone         = "${var.region}-a"
  tags         = ["${var.consulNetworkTag["dc1"]}", "consul-client", "http-server"]

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
      "sudo apt-get -y update",
      "mkdir /home/${var.userName}/vault.d",
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

    content = <<HCL
    ui = true

    storage "consul" {
      address = "127.0.0.1:8500"
      path = "vault/"
    }

    listener "tcp" {
      address = "0.0.0.0:8200"
      cluster_address = "0.0.0.0:8201"
      tls_disable = true
    }

    seal "gcpckms" {
      project = "${var.projectName}"
      region = "global"
      key_ring = "${var.keyRing}"
      crypto_key = "${var.cryptoKey}"
    }

    api_addr = "http://${self.network_interface.0.access_config.0.nat_ip}:8200"
    cluster_addr = "http://${self.network_interface.0.access_config.0.nat_ip}:8201"
    disable_mlock = true
    HCL

    destination = "/home/${var.userName}/vault.d/vault.hcl"
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

    source      = "${var.localPath}/binaries/vault-enterprise_1.0.3+prem_linux_amd64.zip"
    destination = "/home/${var.userName}/vault-enterprise_1.0.3+prem_linux_amd64.zip"
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
        ${jsonencode("id")}: ${jsonencode("vault-client-${count.index}")},
        ${jsonencode("name")}: ${jsonencode("vault")},
        ${jsonencode("port")}: 8200
      }
    }
    JSON

    destination = "/home/${var.userName}/consul.d/vault.json"
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
      ${jsonencode("node_name")}: ${jsonencode("vault-client-${count.index}")},
      ${jsonencode("datacenter")}: ${jsonencode("dc1")},
      ${jsonencode("data_dir")}: ${jsonencode("/home/${var.userName}/consul.d/data")},
      ${jsonencode("bind_addr")}: ${jsonencode("0.0.0.0")},
      ${jsonencode("client_addr")}: ${jsonencode("0.0.0.0")},
      ${jsonencode("advertise_addr")}: ${jsonencode("${self.network_interface.0.access_config.0.nat_ip}")},
      ${jsonencode("retry_join")}: ${jsonencode("${list("provider=gce project_name=${var.userName}-test tag_value=${var.consulNetworkTag["dc1"]}")}")},
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

    content     = "${data.template_file.vault-systemd-client.rendered}"
    destination = "/home/${var.userName}/vault.service"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "${var.userName}"
      private_key = "${file("/Users/${var.userName}/.ssh/id_rsa")}"
    }

    inline = [
      "unzip /home/${var.userName}/vault-enterprise_1.0.3+prem_linux_amd64.zip",
      "unzip /home/${var.userName}/consul_${var.consulVersion}_linux_amd64.zip",
      "sudo mv /home/${var.userName}/consul /bin/",
      "sudo mv /home/${var.userName}/vault /bin/",
      "sudo setcap cap_ipc_lock=+ep /bin/vault",
      "rm /home/${var.userName}/vault-enterprise_1.0.3+prem_linux_amd64.zip",
      "rm /home/${var.userName}/consul_${var.consulVersion}_linux_amd64.zip",
      "sudo mv /home/${var.userName}/*.service /etc/systemd/system/",
      "sudo systemctl start consul-client",
      "sudo systemctl start vault",
    ]
  }
}
