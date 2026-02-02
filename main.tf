module "bastion" {
  source                     = "./modules/bastion"
  compartment_id             = var.compartment_ocid
  environment                = var.environment
  app_name                   = var.app_name
  tags                       = local.tags
  vcn_name                   = var.bastion.vcn_name
  subnet_name                = var.bastion.subnet_name
  bastion_name               = var.bastion.bastion_name
  max_session_ttl_in_seconds = var.bastion.max_session_ttl_in_seconds
}

module "oke" {
  source         = "./modules/container"
  tenancy_ocid   = var.tenancy_ocid
  compartment_id = var.compartment_ocid
  environment    = var.environment
  app_name       = var.app_name
  tags           = local.tags

  vcn_name                    = var.oke.vcn_name
  cluster_name                = var.oke.cluster_name
  cluster_type                = var.oke.cluster_type
  kubernetes_version          = var.oke.kubernetes_version
  cluster_subnet_name         = var.oke.cluster_subnet_name
  loadbalancer_subnet_name    = var.oke.loadbalancer_subnet_name
  worker_subnet_name          = var.oke.worker_subnet_name
  endpoint_nsg_names          = var.oke.endpoint_nsg_names
  cni_type                    = var.oke.cni_type
  services_cidr               = var.oke.services_cidr
  pods_cidr                   = var.oke.pods_cidr
  log_group                   = var.oke.log_group
  instance_dynamic_group      = var.oke.instance_dynamic_group
  policy                      = var.oke.policy
  unified_agent_configuration = var.oke.unified_agent_configuration
  logs                        = var.oke.logs
  node_pools                  = var.oke.node_pools
  autoscaler                  = var.oke.autoscaler
}