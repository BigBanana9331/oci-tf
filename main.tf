terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "7.30.0"
    }
  }
}

provider "oci" {
  region = "ap-singapore-1"
}

variable "tenancy_ocid" {}

variable "compartment_ocid" {}

module "identity" {
  source         = "./modules/identity"
  compartment_id = var.compartment_ocid
}

module "networking" {
  source         = "./modules/networking"
  compartment_id = var.compartment_ocid
  depends_on     = [module.identity]
}

module "security" {
  source         = "./modules/security"
  compartment_id = var.compartment_ocid
  depends_on     = [module.identity]
}

module "container" {
  source         = "./modules/container"
  tenancy_ocid   = var.tenancy_ocid
  compartment_id = var.compartment_ocid
  depends_on     = [module.networking, module.security]
}

module "database" {
  source         = "./modules/database"
  tenancy_ocid   = var.tenancy_ocid
  compartment_id = var.compartment_ocid
  depends_on     = [module.networking, module.security]
}