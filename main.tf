module "bastion" {
  count                      = var.bastion != null ? 1 : 0
  source                     = "./modules/bastion"
  compartment_id             = var.compartment_ocid
  environment                = var.environment
  tags                       = local.tags
  vcn_name                   = var.bastion.vcn_name
  subnet_name                = var.bastion.subnet_name
  bastion_name               = var.bastion.bastion_name
  max_session_ttl_in_seconds = var.bastion.max_session_ttl_in_seconds
}

module "oke" {
  count          = var.oke != null ? 1 : 0
  source         = "./modules/container"
  tenancy_ocid   = var.tenancy_ocid
  compartment_id = var.compartment_ocid
  environment    = var.environment
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

module "mysql" {
  count                   = var.mysql != null ? 1 : 0
  source                  = "./modules/database"
  tenancy_ocid            = var.tenancy_ocid
  compartment_id          = var.compartment_ocid
  environment             = var.environment
  tags                    = local.tags
  vcn_name                = var.mysql.vcn_name
  subnet_name             = var.mysql.subnet_name
  nsg_names               = var.mysql.nsg_names
  shape_name              = var.mysql.shape_name
  display_name            = var.mysql.display_name
  data_storage_size_in_gb = var.mysql.data_storage_size_in_gb
  is_highly_available     = var.mysql.is_highly_available
}