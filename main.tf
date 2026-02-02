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