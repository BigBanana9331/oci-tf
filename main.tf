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


output "shapes" {
  value = module.oke.shapes
}



output "images" {
  value = module.oke.images
}



output "route_tables" {
  value = module.oke.route_tables
}



output "subnets" {
  value = module.oke.subnets
}


output "vcns" {
  value = module.oke.vcns
}



output "security_lists" {
  value = module.oke.security_lists
}



output "nsgs" {
  value = module.oke.network_security_groups
}


output "internet_gateways" {
  value = module.oke.internet_gateways
}


output "nat_gateways" {
  value = module.oke.nat_gateways
}


output "service_gateways" {
  value = module.oke.service_gateways
}

output "compartment_images" {
  value = module.oke.compartment_images
}

output "oracle_linux_images" {
  value = module.oke.oracle_linux_images
}

output "test" {
  value = module.oke.test
}