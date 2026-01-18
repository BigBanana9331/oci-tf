variable "tenancy_ocid" {

}

variable "compartment_id" {

}

module "oke" {
  source          = "./modules/oke"
  compartment_id  = var.compartment_id
  tenancy_ocid    = var.tenancy_ocid
  vcn_cidr_blocks = ["10.0.0.0/16"]
}