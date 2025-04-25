# Provider Configuration
provider "google" {
  project     = "********************************************"
  region      = "northamerica-northeast1"
  zone        = "northamerica-northeast1-a"
  credentials = file("/mnt/data/Infrastructure_through_terraform/scalable-web-server/service_key.json")
}

# Virtual Machine Instance Template
resource "google_compute_instance_template" "web_server_template" {
  name         = "web-server-template"
  machine_type = "e2-medium"

  disk {
    auto_delete   = true
    boot          = true

    source_image = "projects/debian-cloud/global/images/family/debian-11"
    }

  network_interface {
    network = "default"
    access_config {} # Enables an external IP
  }

  tags = ["http-server"] # Used for targeting firewall rules

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y apache2
    systemctl start apache2
    systemctl enable apache2
  EOT
}

# Instance Group Manager
resource "google_compute_instance_group_manager" "web_server_group" {
  name               = "web-server-group"
  base_instance_name = "web-server-instance"
  target_size        = 1
  zone               = "northamerica-northeast1-a"

  version {
    instance_template = google_compute_instance_template.web_server_template.self_link
    name              = "v1"
  }
}

# Autoscaler
resource "google_compute_autoscaler" "web_server_autoscaler" {
  name   = "web-server-autoscaler"
  zone   = "northamerica-northeast1-a"
  target = google_compute_instance_group_manager.web_server_group.self_link

  autoscaling_policy {
    max_replicas = 5
    min_replicas = 1

    cpu_utilization {
      target = 0.6 # Autoscaling triggers when CPU utilization exceeds 60%
    }
  }
}

# Firewall Rule
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"] # Allows traffic from all IPs (internet)

  target_tags = ["http-server"] # Applied to instances with this tag
}

# Output (Fixed)
output "instance_template_self_link" {
  value = google_compute_instance_template.web_server_template.self_link
}
