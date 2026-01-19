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

data "oci_core_services" "services" {}

data "oci_identity_availability_domains" "availability_domains" {
  compartment_id = var.tenancy_ocid
}


output "services" {
  value = data.oci_core_services.services
}

output "ads" {
  value = data.oci_identity_availability_domains.availability_domains
}

# module "vcn" {
#   source          = "./modules/vcn"
#   tenancy_ocid    = var.tenancy_ocid
#   compartment_id  = var.compartment_id
#   vcn_cidr_blocks = ["10.0.0.0/16"]
# }