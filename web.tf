resource "google_compute_instance_template" "web" {
  name_prefix  = "web-"
  machine_type = "e2-micro"
  region       = var.region1
  tags         = ["allow-ssh", "allow-http", "web"]

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }
  disk {
    disk_type    = "pd-standard"
    source_image = "debian-cloud/debian-10"
    disk_size_gb = 10
    auto_delete  = true
    boot         = true
  }
  network_interface {
    network = google_compute_network.poc.id
    subnetwork = google_compute_subnetwork.web.id
  }
  metadata = {
    startup-script = <<-EOF
      #!/bin/bash
      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y docker.io jq
      NAME=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/hostname")
      IP=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip")
      docker run -d --restart unless-stopped --name gcp_poc -e GCE_NAME=$NAME -e GCE_PRIVATE_IP=$IP -p 80:80 huangyingting/gcp_poc
    EOF
  }
  service_account {
    scopes = [
      "service-management",
      "compute-rw",
      "storage-ro",
      "logging-write",
      "monitoring-write",
      "service-control",
    ]
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "web" {
  name   = substr("rigm-web-${md5(google_compute_instance_template.web.name)}", 0, 63)
  region = var.region1
  version {
    instance_template = google_compute_instance_template.web.id
  }
  base_instance_name        = "web"
  distribution_policy_zones = var.region1_zones
  target_size               = 1
  wait_for_instances        = true
  named_port {
    name = "http"
    port = 80
  }  
  timeouts {
    create = "15m"
    update = "15m"
  }
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    google_compute_router_nat.nat
  ]
}

resource "google_compute_region_autoscaler" "web" {
  name = substr("ras-web-${md5(google_compute_instance_template.web.name)}", 0, 63)
  region = var.region1
  target = google_compute_region_instance_group_manager.web.id

  autoscaling_policy {
    max_replicas    = 2
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}