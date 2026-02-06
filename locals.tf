locals {
  tags = {
    freeformTags = {
      Environment = var.environment
      Application = var.app_name
      CreatedBy   = "Terraform"
    }
    definedTags = {}
  }

  image_id = [
    for source in data.oci_containerengine_node_pool_option.node_pool_option.sources :
    source.image_id if strcontains(source.source_name, "Gen2-GPU") == false
  ][0]

  subnets = {
    for subnet in data.oci_core_subnets.subnets.subnets : subnet.display_name => subnet.id
  }

  nsgs = {
    for nsg in data.oci_core_network_security_groups.network_security_groups.network_security_groups : nsg.display_name => nsg.id
  }
}