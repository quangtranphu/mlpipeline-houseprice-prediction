# Ref: https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/blob/master/examples/simple_autopilot_public
# To define that we will use GCP
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.0.0" // Provider version
    }
  }
  required_version = "1.9.7" // Terraform version
}

// The library with methods for creating and
// managing the infrastructure in GCP, this will
// apply to all the resources in the project
provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

// Google Kubernetes Engine
resource "google_container_cluster" "quangtp-gke" {
  name     = "${var.project_id}-new-gke"
  location = var.zone
 
  // Enabling Autopilot for this cluster
  # enable_autopilot = true
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false 
  
  # // Enable Istio (beta)
  # // https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#nested_istio_config
  # // not yet supported on Autopilot mode
  # addons_config {
  #   istio_config {
  #     disabled = false
  #     auth     = "AUTH_NONE"
  #   }
  # }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  location   = google_container_cluster.quangtp-gke.location
  cluster    = google_container_cluster.quangtp-gke.name
  node_count = 2

  node_config {
    preemptible  = true
    machine_type = "e2-standard-4"
    disk_size_gb = 30
    image_type = "COS_CONTAINERD"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    # service_account = google_service_account.default.email
    # oauth_scopes    = [
    #   "https://www.googleapis.com/auth/cloud-platform"
    # ]
  }
}

resource "google_storage_bucket" "quangtp-bucket" {
  name          = var.bucket
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true
}

resource "google_compute_instance" "jenkins_mlops1" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = var.boot_disk_image
      size = var.boot_disk_size
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = var.ssh_keys
  }
}

resource "google_compute_firewall" "firewall_mlops1" {
  name    = var.firewall_name
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8081", "50000", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"] // Allow all traffic
}