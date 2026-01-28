variable "tenancy_ocid" {
  type = string
}
variable "compartment_ocid" {
  type = string
}
variable "region" {
  type = string
}

provider "oci" {
  region = var.region
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
  region         = var.region
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

module "container" {
  source         = "./modules/container"
  tenancy_ocid   = var.tenancy_ocid
  compartment_id = var.compartment_ocid
  depends_on     = [module.networking, module.loggroup, module.vault]
}

# module "database" {
#   source         = "./modules/database"
#   tenancy_ocid   = var.tenancy_ocid
#   compartment_id = var.compartment_ocid
#   depends_on     = [module.networking, module.vault]
# }


# data "oci_containerengine_cluster_kube_config" "cluster_kube_config" {
#   cluster_id = module.container.cluster_id
#   depends_on = [module.container]
# }

# data "oci_resourcemanager_private_endpoint_reachable_ip" "private_endpoint_reachable_ip" {
#   #Required
#   private_endpoint_id = module.privateendpoint.id
#   private_ip          = "10.0.0.2"
#   depends_on          = [module.privateendpoint]
# }

# provider "kubernetes" {
#   host                   = "https://${data.oci_resourcemanager_private_endpoint_reachable_ip.private_endpoint_reachable_ip.ip_address}:6443"
#   cluster_ca_certificate = base64decode(yamldecode(data.oci_containerengine_cluster_kube_config.cluster_kube_config.content)["clusters"][0]["cluster"]["certificate-authority-data"])
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     args = ["ce", "cluster", "generate-token", "--cluster-id",
#     module.container.cluster_id, "--region", var.region]
#     command = "oci"
#   }
# }

# module "kubernetes" {
#   source         = "./modules/kubernetes"
#   compartment_id = var.compartment_ocid
#   subnet_id      = module.networking.service_ib_subnet_id

#   depends_on = [ module.container, module.privateendpoint ]
# }