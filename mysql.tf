resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "poc_primary" {
  provider         = google-beta
  name             = "mysql-primary-${random_id.db_name_suffix.hex}"
  region           = var.region1
  database_version = "MYSQL_5_7"
  settings {
    tier              = "db-f1-micro"
    disk_size         = 10
    availability_type = "REGIONAL"
    backup_configuration {
      binary_log_enabled = true
      enabled            = true
    }
  }
}

resource "google_sql_database_instance" "poc_replica" {
  provider             = google-beta
  name                 = "mysql-replica-${random_id.db_name_suffix.hex}"
  region               = var.region2
  master_instance_name = google_sql_database_instance.poc_primary.id
  settings {
    tier                   = "db-f1-micro"
    disk_size              = 10
    crash_safe_replication = true
  }
}

resource "google_sql_database" "poc" {
  provider = google-beta
  name     = "poc"
  instance = google_sql_database_instance.poc_primary.name
}

resource "google_sql_user" "poc" {
  provider = google-beta
  name     = var.db_username
  instance = google_sql_database_instance.poc_primary.name
  host     = "%"
  password = var.db_password
}
