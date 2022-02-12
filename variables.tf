variable "vpc_pid" {
  type        = string
  description = "GCP project ID of the host project."
  default     = "gcp-poc-8102795"
}

variable "region1" {
  type        = string
  description = "GCP region where resources are created."
  default     = "asia-southeast1"
}

variable "region1_zones" {
  type        = list(any)
  description = "GCP zone in the var.region where resources are created."
  default     = ["asia-southeast1-a", "asia-southeast1-b", "asia-southeast1-c"]
}

variable "region2" {
  type        = string
  description = "GCP region where resources are created."
  default     = "asia-east2"
}

variable "region2_zones" {
  type        = list(any)
  description = "GCP zone in the var.region where resources are created."
  default     = ["asia-east2-a", "asia-east2-b", "asia-east2-c"]
}

variable "bucket_name" {
  type        = string
  description = "GCP bucket name"
  default     = "gcp-poc-cdn"
}

variable "bucket_location" {
  type        = string
  description = "GCP bucket location"
  default     = "ASIA"
}

variable "email_address" {
  type    = string
  default = ""
}

variable "domain_name" {
  type    = string
  default = ""
}

variable "certificate_name" {
  type    = string
  default = ""
}

variable "dns_zone_resource_group_name" {
  type    = string
  default = ""
}

variable "azure_client_id" {
  type    = string
  default = ""
}

variable "azure_client_secret" {
  type    = string
  default = ""
}

variable "azure_subscription_id" {
  type    = string
  default = ""
}

variable "azure_tenant_id" {
  type    = strig
  default = ""
}
