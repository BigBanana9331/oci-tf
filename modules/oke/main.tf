data "oci_core_vcns" "vcns" {
  compartment_id = var.compartment_id
  display_name   = var.vcn_name
}

data "oci_core_subnets" "subnets" {
  compartment_id = var.compartment_id
  vcn_id         = data.oci_core_vcns.vcns.vcns[0].id
}

resource "oci_core_network_security_group" "network_security_group" {
  #Required
  for_each       = var.nsgs != null ? var.nsgs : {}
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = each.key
}

resource "oci_core_network_security_group_security_rule" "network_security_group_security_rule" {
  for_each                  = var.nsgs.security_rules != null ? var.nsgs.security_rules : []
  network_security_group_id = oci_core_network_security_group.network_security_group[each.key].id
  direction                 = each.value.direction
  protocol                  = each.value.protocol
  source                    = each.value.source
  destination               = each.value.destination
  destination_type          = each.value.destination_type
  source_type               = each.value.source_type
  stateless                 = each.value.stateless
  description               = each.value.description

  icmp_options {
    type = each.value.icmp_options.type
    code = each.value.icmp_options.code
  }

  tcp_options {
    destination_port_range {
      max = each.value.tcp_options.destination_port_range.max
      min = each.value.tcp_options.destination_port_range.min
    }
    source_port_range {
      max = each.value.tcp_options.source_port_range.max
      min = each.value.tcp_options.source_port_range.min
    }
  }
  udp_options {
    destination_port_range {
      max = each.value.udp_options.destination_port_range.max
      min = each.value.udp_options.destination_port_range.min
    }
    source_port_range {
      max = each.value.udp_options.source_port_range.max
      min = each.value.udp_options.source_port_range.min
    }
  }
}

resource "oci_containerengine_cluster" "cluster" {
  name               = var.cluster_name
  compartment_id     = var.compartment_id
  vcn_id             = data.oci_core_vcns.vcns.vcns[0].id
  type               = var.cluster_type
  kubernetes_version = var.kubernetes_version

  endpoint_config {
    subnet_id            = data.oci_core_subnets.subnets.subnets[var.cluster_subnet_name].id
    is_public_ip_enabled = var.is_public_endpoint_enabled
    nsg_ids              = var.endpoint_nsg_ids
  }

  dynamic "cluster_pod_network_options" {
    for_each = var.cni_types
    content {
      cni_type = each.value
    }
  }

  options {
    service_lb_subnet_ids = [data.oci_core_subnets.subnets.subnets[var.loadbalancer_subnet_name].id]

    kubernetes_network_config {
      pods_cidr     = var.pods_cidr
      services_cidr = var.services_cidr
    }

    admission_controller_options {
      is_pod_security_policy_enabled = var.is_pod_security_policy_enabled
    }
  }
}

resource "oci_containerengine_addon" "addon" {
  for_each                         = var.addons
  addon_name                       = each.key
  cluster_id                       = oci_containerengine_cluster.cluster.id
  remove_addon_resources_on_delete = each.value.remove_addon_resources_on_delete
  override_existing                = each.value.override_existing
  version                          = each.value.version

  dynamic "configurations" {
    for_each = each.value.configurations
    content {
      key   = each.key
      value = each.value
    }
  }

}

resource "oci_containerengine_node_pool" "node_pool" {
  for_each = var.node_pools

  name               = each.key
  cluster_id         = oci_containerengine_cluster.cluster.id
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  node_shape         = each.value.node_shape


  node_shape_config {
    memory_in_gbs = each.key.value.node_shape_memory_in_gbs
    ocpus         = each.key.value.node_shape_ocpus
  }

  node_pool_cycling_details {
    cycle_modes             = each.value.cycle_modes
    is_node_cycling_enabled = each.key.value.is_node_cycling_enabled
    maximum_surge           = each.value.maximum_surge
    maximum_unavailable     = each.value.maximum_unavailable
  }

  node_eviction_node_pool_settings {
    eviction_grace_duration              = each.value.eviction_grace_duration
    is_force_action_after_grace_duration = each.value.is_force_action_after_grace_duration
    is_force_delete_after_grace_duration = each.value.is_force_delete_after_grace_duration
  }

  node_config_details {
    size    = each.value.node_pool_size
    nsg_ids = each.value.node_nsg_ids
    placement_configs {
      #Required
      subnet_id           = data.oci_core_subnets.subnets.subnets[var.worker_subnet_name].id
      availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[0].name
    }
    node_pool_pod_network_option_details {
      cni_type = each.value.cni_type
    }
  }
}