# module "bastion" {
#   count                      = var.bastion != null ? 1 : 0
#   source                     = "./modules/bastion"
#   compartment_id             = var.compartment_ocid
#   environment                = var.environment
#   tags                       = local.tags
#   subnet_id                  = local.subnets[join("-", [var.environment, var.bastion.subnet_name])]
#   bastion_name               = var.bastion.bastion_name
#   max_session_ttl_in_seconds = var.bastion.max_session_ttl_in_seconds
# }

# module "apigw" {
#   count          = var.apigw != null ? 1 : 0
#   source         = "./modules/apigateway"
#   compartment_id = var.compartment_ocid
#   environment    = var.environment
#   tags           = local.tags
#   subnet_id      = var.apigw.subnet_name
#   nsg_ids        = [for nsg in var.apigw.nsg_names : lookup(local.nsgs, join("-", [var.environment, nsg]))]
# }

# module "oke" {
#   count                       = var.oke != null ? 1 : 0
#   source                      = "./modules/container"
#   compartment_id              = var.compartment_ocid
#   environment                 = var.environment
#   tags                        = local.tags
#   cluster_name                = var.oke.cluster_name
#   cluster_type                = var.oke.cluster_type
#   kubernetes_version          = var.oke.kubernetes_version
#   vcn_id                      = data.oci_core_vcns.vcns.virtual_networks[0].id
#   cluster_subnet_id           = var.oke.cluster_subnet_name
#   loadbalancer_subnet_ids     = [for subnet in var.oke.loadbalancer_subnet_ids: lookup(local.subnets, subnet) ]
#   worker_subnet_id            = var.oke.worker_subnet_name
#   endpoint_nsg_ids            = var.oke.endpoint_nsg_names
#   cni_type                    = var.oke.cni_type
#   services_cidr               = var.oke.services_cidr
#   pods_cidr                   = var.oke.pods_cidr
#   log_group                   = var.oke.log_group
#   instance_dynamic_group      = var.oke.instance_dynamic_group
#   policy                      = var.oke.policy
#   unified_agent_configuration = var.oke.unified_agent_configuration
#   logs                        = var.oke.logs
#   node_pools                  = var.oke.node_pools
#   autoscaler                  = var.oke.autoscaler
# }

module "mysql" {
  count                   = var.mysql != null ? 1 : 0
  source                  = "./modules/database"
  tenancy_ocid            = var.tenancy_ocid
  compartment_id          = var.compartment_ocid
  environment             = var.environment
  tags                    = local.tags
  subnet_id               = local.subnets[var.mysql.subnet_name]
  nsg_ids                 = [for nsg in var.mysql.nsg_names : lookup(nsg, local.nsgs)]
  availability_domain     = data.oci_identity_availability_domain.ad.id
  shape_name              = var.mysql.shape_name
  display_name            = var.mysql.display_name
  data_storage_size_in_gb = var.mysql.data_storage_size_in_gb
  is_highly_available     = var.mysql.is_highly_available
  admin_password          = base64decode(data.oci_secrets_secretbundle.admin_password_secretbundle.secret_bundle_content[0].content)
  key_id                  = data.oci_kms_keys.keys[var.mysql.key_name]
}