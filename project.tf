locals {
  admin_enabled_apis = [
    "bigquery.googleapis.com",
    "cloudapis.googleapis.com",
    "clouddebugger.googleapis.com",
    "cloudtrace.googleapis.com",
    "compute.googleapis.com",
    "datastore.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "oslogin.googleapis.com",
    "pubsub.googleapis.com",
    "servicemanagement.googleapis.com",
    "serviceusage.googleapis.com",
    "sql-component.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "dns.googleapis.com",
    "sqladmin.googleapis.com"
  ]
}

data "google_billing_account" "acct" {
  billing_account = var.billing_account
  open            = true
}

/*
resource "google_project" "gcp_poc" {
  name            = "GCP POC"
  project_id      = var.vpc_pid
  org_id          = var.org_id
  billing_account = data.google_billing_account.acct.id
}
*/

data "google_project" "gcp_poc" {
  project_id      = var.vpc_pid
}

resource "google_project_service" "enabled-apis" {
  for_each                   = toset(local.admin_enabled_apis)
  project                    = data.google_project.gcp_poc.project_id
  service                    = each.value
  disable_dependent_services = true
  disable_on_destroy         = true
}
