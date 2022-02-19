resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_compute_global_address" "private_ip_alloc" {
  provider      = google-beta
  name          = "private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.poc.id
}

resource "google_service_networking_connection" "sql" {
  provider                = google-beta
  network                 = google_compute_network.poc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}

resource "google_sql_database_instance" "primary" {
  provider         = google-beta
  name             = "db-primary-${random_id.db_name_suffix.hex}"
  region           = var.region1
  database_version = "MYSQL_5_7"
  settings {
    tier              = "db-f1-micro"
    disk_size         = 10
    availability_type = "REGIONAL"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.poc.id
    }
    backup_configuration {
      binary_log_enabled = true
      enabled            = true
    }
  }
  deletion_protection = false
  depends_on          = [google_service_networking_connection.sql]
}

resource "google_sql_database_instance" "replica" {
  provider             = google-beta
  name                 = "db-replica-${random_id.db_name_suffix.hex}"
  region               = var.region2
  database_version     = "MYSQL_5_7"
  master_instance_name = google_sql_database_instance.primary.id
  settings {
    tier      = "db-f1-micro"
    disk_size = 10
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.poc.id
    }
  }
  deletion_protection = false
  depends_on          = [google_service_networking_connection.sql]
}

resource "google_sql_database" "db" {
  provider = google-beta
  name     = "poc"
  instance = google_sql_database_instance.primary.name
}

resource "google_sql_user" "user" {
  provider = google-beta
  name     = var.db_username
  instance = google_sql_database_instance.primary.name
  host     = "%"
  password = var.db_password
}
