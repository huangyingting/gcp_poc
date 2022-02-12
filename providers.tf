terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.96"
    }
    google = {
      version = "~> 4.10"
    }
    google-beta = {
      version = "~> 4.10"
    }
    acme = {
      source  = "vancluever/acme"
      version = "=2.7.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.1"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "google" {
  project = var.vpc_pid
}

provider "google-beta" {
  project = var.vpc_pid
}

provider "acme" {
  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
}
