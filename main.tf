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

variable "compartment_id" {}

module "vcn" {
  source          = "./modules/vcn"
  tenancy_ocid    = var.tenancy_ocid
  compartment_id  = var.compartment_id
  vcn_cidr_blocks = ["10.0.0.0/16"]
}

module "oke" {
  source         = "./modules/oke"
  compartment_id = var.compartment_id
  tenancy_ocid   = var.tenancy_ocid
  depends_on     = [module.vcn]
}