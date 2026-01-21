data "oci_core_shapes" "shapes" {
  compartment_id = var.compartment_id
}

output "shapes" {
  value = data.oci_core_shapes.shapes
}

data "oci_core_images" "images" {
  compartment_id = var.compartment_id
}

output "images" {
  value = data.oci_core_images.images
}

data "oci_core_route_tables" "route_tables" {
  #Required
  compartment_id = var.compartment_id
}

output "route_tables" {
  value = data.oci_core_route_tables.route_tables
}

data "oci_core_subnets" "subnets" {
  #Required
  compartment_id = var.compartment_id
}

output "subnets" {
  value = data.oci_core_subnets.subnets
}

data "oci_core_vcns" "vcns" {
  #Required
  compartment_id = var.compartment_id
}

output "vcns" {
  value = data.oci_core_vcns.vcns
}

data "oci_core_security_lists" "security_lists" {
  #Required
  compartment_id = var.compartment_id
}

output "security_lists" {
  value = data.oci_core_security_lists.security_lists
}

data "oci_core_network_security_groups" "network_security_groups" {
  compartment_id = var.compartment_id
}

output "network_security_groups" {
  value = data.oci_core_network_security_groups.network_security_groups
}

data "oci_core_internet_gateways" "internet_gateways" {
  #Required
  compartment_id = var.compartment_id
}

output "internet_gateways" {
  value = data.oci_core_internet_gateways.internet_gateways
}

data "oci_core_nat_gateways" "nat_gateways" {
  #Required
  compartment_id = var.compartment_id
}

output "nat_gateways" {
  value = data.oci_core_nat_gateways.nat_gateways
}

data "oci_core_service_gateways" "service_gateways" {
  #Required
  compartment_id = var.compartment_id
}

output "service_gateways" {
  value = data.oci_core_service_gateways.service_gateways
}

data "oci_containerengine_node_pool_option" "node_pool_option" {
  node_pool_option_id = "all"
}

locals {
  all_images          = data.oci_core_images.images.images
  all_sources         = data.oci_containerengine_node_pool_option.node_pool_option.sources
  compartment_images  = [for image in local.all_images : image.id if length(regexall("Oracle-Linux-[0-9]*.[0-9]*-20[0-9]*", image.display_name)) > 0]
  oracle_linux_images = [for source in local.all_sources : source.image_id if length(regexall("Oracle-Linux-[0-9]*.[0-9]*-20[0-9]*", source.source_name)) > 0]
  image_id            = tolist(setintersection(toset(local.compartment_images), toset(local.oracle_linux_images)))[0]
}

output "compartment_images" {
  value = local.compartment_images
}

output "oracle_linux_images" {
  value = local.oracle_linux_images
}

output "test" {
  value = [for s in data.oci_core_subnets.subnets.subnets : s.id if s.display_name == "loadbalancers"]
}

# data "oci_identity_availability_domains" "availability_domains" {
#   compartment_id = var.tenancy_ocid
# }

# data "oci_core_vcns" "vcns" {
#   compartment_id = var.compartment_id
#   display_name   = var.vcn_name
# }

# data "oci_core_subnets" "cluster_subnet" {
#   compartment_id = var.compartment_id
#   vcn_id         = data.oci_core_vcns.vcns.virtual_networks[0].id
#   display_name   = var.cluster_subnet_name
# }

# data "oci_core_network_security_groups" "network_security_groups" {
#   for_each = var.node_pools
#   #Optional
#   compartment_id = var.compartment_id
#   display_name   = each.value.node_nsg_ids
#   vcn_id         = data.oci_core_vcns.vcns.virtual_networks[0].id
# }

# data "oci_core_subnets" "loadbalancer_subnet" {
#   compartment_id = var.compartment_id
#   vcn_id         = data.oci_core_vcns.vcns.virtual_networks[0].id
#   display_name   = var.loadbalancer_subnet_name
# }

# data "oci_core_subnets" "worker_subnet" {
#   compartment_id = var.compartment_id
#   vcn_id         = data.oci_core_vcns.vcns.virtual_networks[0].id
#   display_name   = var.worker_subnet_name
# }

# data "oci_containerengine_node_pool_option" "node_pool_option" {
#   node_pool_option_id = "all"
# }

# data "oci_core_images" "shape_specific_images" {
#   #Required
#   compartment_id = var.tenancy_ocid
#   shape          = "VM.Standard.E3.Flex"
# }

# locals {
#   all_images          = data.oci_core_images.shape_specific_images.images
#   all_sources         = data.oci_containerengine_node_pool_option.node_pool_option.sources
#   compartment_images  = [for image in local.all_images : image.id if length(regexall("Oracle-Linux-[0-9]*.[0-9]*-20[0-9]*", image.display_name)) > 0]
#   oracle_linux_images = [for source in local.all_sources : source.image_id if length(regexall("Oracle-Linux-[0-9]*.[0-9]*-20[0-9]*", source.source_name)) > 0]
#   image_id            = tolist(setintersection(toset(local.compartment_images), toset(local.oracle_linux_images)))[0]
# }

# resource "oci_containerengine_cluster" "cluster" {
#   name               = var.cluster_name
#   compartment_id     = var.compartment_id
#   vcn_id             = data.oci_core_vcns.vcns.virtual_networks[0].id
#   type               = var.cluster_type
#   kubernetes_version = var.kubernetes_version

#   endpoint_config {
#     subnet_id            = data.oci_core_subnets.cluster_subnet.subnets[0].id
#     is_public_ip_enabled = var.is_public_endpoint_enabled
#     nsg_ids              = var.endpoint_nsg_ids
#   }

#   cluster_pod_network_options {
#     cni_type = var.cni_type
#   }

#   options {
#     service_lb_subnet_ids = [data.oci_core_subnets.loadbalancer_subnet.subnets[0].id]

#     kubernetes_network_config {
#       pods_cidr     = var.pods_cidr
#       services_cidr = var.services_cidr
#     }

#     admission_controller_options {
#       is_pod_security_policy_enabled = var.is_pod_security_policy_enabled
#     }
#   }
# }

# resource "oci_containerengine_addon" "addon" {
#   for_each                         = var.addons != null ? var.addons : {}
#   addon_name                       = each.key
#   cluster_id                       = oci_containerengine_cluster.cluster.id
#   remove_addon_resources_on_delete = each.value.remove_addon_resources_on_delete
#   override_existing                = each.value.override_existing
#   version                          = each.value.version

#   dynamic "configurations" {
#     for_each = each.value.configurations
#     content {
#       key   = each.key
#       value = each.value
#     }
#   }

# }

# resource "oci_containerengine_node_pool" "node_pool" {
#   for_each = var.node_pools

#   name               = each.key
#   cluster_id         = oci_containerengine_cluster.cluster.id
#   compartment_id     = var.compartment_id
#   kubernetes_version = var.kubernetes_version
#   node_shape         = each.value.node_shape


#   node_shape_config {
#     memory_in_gbs = each.value.node_shape_memory_in_gbs
#     ocpus         = each.value.node_shape_ocpus
#   }

#   node_pool_cycling_details {
#     cycle_modes             = each.value.cycle_modes
#     is_node_cycling_enabled = each.value.is_node_cycling_enabled
#     maximum_surge           = each.value.maximum_surge
#     maximum_unavailable     = each.value.maximum_unavailable
#   }

#   node_eviction_node_pool_settings {
#     eviction_grace_duration              = each.value.eviction_grace_duration
#     is_force_action_after_grace_duration = each.value.is_force_action_after_grace_duration
#     is_force_delete_after_grace_duration = each.value.is_force_delete_after_grace_duration
#   }

#   node_config_details {
#     size    = each.value.node_pool_size
#     nsg_ids = each.value.node_nsg_ids
#     placement_configs {
#       subnet_id           = data.oci_core_subnets.worker_subnet.subnets[0].id
#       availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[0].name
#     }
#     node_pool_pod_network_option_details {
#       cni_type = each.value.cni_type
#     }
#   }

#   node_source_details {
#     image_id    = local.image_id
#     source_type = "IMAGE"
#   }
# }