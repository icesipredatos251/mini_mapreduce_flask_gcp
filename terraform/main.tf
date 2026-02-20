provider "google" {
  project = var.project
  region  = var.region
}

resource "google_compute_network" "vpc_network" {
  name                    = "mapreduce-network"
  auto_create_subnetworks = true
}

resource "google_compute_firewall" "allow_flask" {
  name    = "allow-flask"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["5000"]
  }

  source_ranges = ["0.0.0.0/0"] # Allowed for external testing, but narrow in production
}

# Add firewall for SSH
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_storage_bucket" "input_bucket" {
  name          = "${var.project}-mapreduce-bucket"
  location      = var.region
  force_destroy = true
}

resource "google_compute_instance" "master" {
  name         = "master"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    sudo apt update && sudo apt install -y python3-venv python3-pip
  EOT

  service_account {
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_instance" "worker" {
  count        = var.worker_count
  name         = "worker-${count.index + 1}"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    sudo apt update && sudo apt install -y python3-venv python3-pip
  EOT

  service_account {
    scopes = ["cloud-platform"]
  }
}
