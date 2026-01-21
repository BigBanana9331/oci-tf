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

module "vcn" {
  source         = "./modules/vcn"
  tenancy_ocid   = var.tenancy_ocid
  compartment_id = var.compartment_ocid
}

module "oke" {
  source         = "./modules/oke"
  tenancy_ocid   = var.tenancy_ocid
  compartment_id = var.compartment_ocid
  depends_on     = [module.vcn]
}

output "node_pool_options" {
  value = module.oke.node_pool_options
}