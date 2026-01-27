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

module "loggroup" {
  source         = "./modules/logging"
  compartment_id = var.compartment_ocid
  depends_on     = [module.tag]
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

module "artifact" {
  source         = "./modules/artifact"
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

module "bastion" {
  source         = "./modules/bastion"
  compartment_id = var.compartment_ocid
  depends_on     = [module.networking]
}

module "privateendpoint" {
  source         = "./modules/privateendpoint"
  compartment_id = var.compartment_ocid
  depends_on     = [module.networking]
}

module "apigateway" {
  source         = "./modules/apigateway"
  compartment_id = var.compartment_ocid
  depends_on     = [module.networking]
}

# module "container" {
#   source         = "./modules/container"
#   tenancy_ocid   = var.tenancy_ocid
#   compartment_id = var.compartment_ocid
#   depends_on     = [module.networking, module.loggroup]
# }

module "database" {
  source         = "./modules/database"
  tenancy_ocid   = var.tenancy_ocid
  compartment_id = var.compartment_ocid
  depends_on     = [module.networking, module.vault]
}