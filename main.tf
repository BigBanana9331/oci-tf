module "vcn" {
  for_each       = var.vcns
  source         = "./modules/networking"
  app_name       = var.app_name
  environment    = var.environment
  compartment_id = var.compartment_ocid
  tags           = var.tags
  vcn_name       = each.key
  cidr_blocks    = each.value.cidr_blocks
  route_tables   = each.value.route_tables
  subnets        = each.value.subnets
  nsgs           = each.value.nsgs
}