resource "google_compute_network" "poc" {
  provider                = google-beta
  name                    = "poc-net"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "web" {
  provider      = google-beta
  name          = "web-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region1
  network       = google_compute_network.poc.id
}

resource "google_compute_subnetwork" "proxy" {
  provider      = google-beta
  name          = "proxy-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region1
  network       = google_compute_network.poc.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}

resource "google_compute_router" "router" {
  name    = "router-${var.region1}"
  region  = var.region1
  network = google_compute_network.poc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat-${var.region1}"
  router                             = google_compute_router.router.name
  region                             = var.region1
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.web.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_compute_firewall" "allow_http" {
  name        = "allow-http"
  network     = google_compute_network.poc.id
  target_tags = ["allow-http"]
  source_ranges = [
    "0.0.0.0/0",
  ]
  allow {
    protocol = "tcp"
    ports    = ["80", ]
  }
}

resource "google_compute_firewall" "allow_ssh" {
  name        = "allow-ssh"
  network     = google_compute_network.poc.id
  target_tags = ["allow-ssh"]
  source_ranges = [
    "0.0.0.0/0",
  ]
  allow {
    protocol = "tcp"
    ports    = ["22", ]
  }
}

resource "google_compute_firewall" "allow_web_subnet" {
  name          = "allow-web-subnet"
  network       = google_compute_network.poc.id
  source_ranges = ["10.0.1.0/24"]
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
  direction = "INGRESS"
}
