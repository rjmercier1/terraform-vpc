provider "google" {
  project = var.project
  region  = var.region
}

resource "google_compute_instance" "worker" {
  name         = "${var.network}-worker"
  machine_type = "e2-micro"
  zone         = "${var.region}-b"
  tags         = ["no-ip", "externalssh"]
  boot_disk {
    initialize_params {
      image = "ubuntu-2004-focal-v20220204"
    }
  }
  network_interface {
    network    = var.network
    subnetwork = google_compute_subnetwork.private_subnet.name
  }
  depends_on = [google_compute_firewall.firewall, google_compute_firewall.webserverrule]

  metadata = {
    ssh-keys = "${var.user}:${file(var.publickeypath)}"
  }
}

resource "google_compute_instance" "gw" {
  name         = "${var.network}-gw"
  machine_type = "e2-micro"
  zone         = "${var.region}-b"
  tags         = ["externalssh", "webserver", "natinternal"]
  boot_disk {
    initialize_params {
      image = "ubuntu-2004-focal-v20220204"
    }
  }
  can_ip_forward = true
  network_interface {
    network    = var.network
    subnetwork = google_compute_subnetwork.public_subnet.name

    access_config {
      nat_ip = google_compute_address.static.address
    }
  }

  #  provisioner "remote-exec" {
  #    connection {
  #      host        = google_compute_address.static.address
  #      type        = "ssh"
  #      user        = var.user
  #      timeout     = "500s"
  #      private_key = file(var.privatekeypath)
  #    }
  #    inline = [
  #      "sudo yum -y install epel-release",
  #      "sudo yum -y install nginx",
  #      "sudo nginx -v",
  #    ]
  #  }

  # Ensure firewall rule is provisioned before server, so that SSH doesn't fail.
  depends_on = [google_compute_firewall.firewall, google_compute_firewall.webserverrule]
  service_account {
    email  = var.email
    scopes = ["compute-ro"]
  }
  metadata = {
    ssh-keys = "${var.user}:${file(var.publickeypath)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo iptables ! -o lo -t nat -A POSTROUTING -j MASQUERADE",
      "sudo sh -c 'iptables-save > /etc/iptables.rules'",

      "sudo sh -c 'echo #\\!/bin/sh > /etc/network/if-pre-up.d/iptablesrestore'",
      "sudo sh -c 'echo iptables-restore /etc/iptables.rules >> /etc/network/if-pre-up.d/iptablesrestore'",
      "sudo sh -c 'echo exit 0 >> /etc/network/if-pre-up.d/iptablesrestore'",
      "sudh chmod +x /etc/network/if-pre-up.d/iptablesrestore",

      "sudo sh -c 'echo #!/bin/sh > /etc/network/if-pre-up.d/iptablesrestore'",
      "sudo sh -c 'echo net.ipv4.ip_forward=1 > /etc/sysctl.d/20-ipv4_forward.conf'",
      "sudo sysctl net.ipv4.ip_forward=1"
    ]
  }
  connection {
    user        = var.user
    host        = google_compute_address.static.address
    private_key = file("${var.privatekeypath}")
  }
}
