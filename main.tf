terraform {
  required_version = ">= 1.5.7"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "7.30.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.8.0"
    }
  }
}

provider "oci" {
  region = "ap-singapore-1"
}

variable "tenancy_ocid" {
  type = string
}
variable "compartment_ocid" {
  type = string
}

module "tag" {
  source         = "./modules/tag"
  compartment_id = var.compartment_ocid
}

module "vault" {
  source         = "./modules/vault"
  compartment_id = var.compartment_ocid
  depends_on     = [module.tag]
}

module "networking" {
  source         = "./modules/networking"
  compartment_id = var.compartment_ocid
  depends_on     = [module.tag]
}

module "queue" {
  source         = "./modules/queue"
  compartment_id = var.compartment_ocid
  depends_on     = [module.vault]
}

module "bucket" {
  source         = "./modules/objstorage"
  compartment_id = var.compartment_ocid
  depends_on     = [module.vault]
}

# module "file" {
#   source         = "./modules/filestorage"
#   tenancy_ocid   = var.tenancy_ocid
#   compartment_id = var.compartment_ocid
#   depends_on     = [module.vault]
# }

module "bastion" {
  source         = "./modules/bastion"
  compartment_id = var.compartment_ocid
  depends_on     = [module.networking]
}

module "apigateway" {
  source         = "./modules/apigateway"
  compartment_id = var.compartment_ocid
  depends_on     = [module.networking]
}

module "container" {
  source         = "./modules/container"
  tenancy_ocid   = var.tenancy_ocid
  compartment_id = var.compartment_ocid
  depends_on     = [module.networking]
}

module "database" {
  source         = "./modules/database"
  tenancy_ocid   = var.tenancy_ocid
  compartment_id = var.compartment_ocid
  depends_on     = [module.networking, module.vault]
}