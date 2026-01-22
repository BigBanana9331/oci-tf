data "oci_identity_availability_domains" "availability_domains" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_vcns" "vcns" {
  compartment_id = var.compartment_id
  display_name   = var.vcn_name
}

data "oci_core_subnets" "subnets" {
  compartment_id = var.compartment_id
  vcn_id         = data.oci_core_vcns.vcns.virtual_networks[0].id
}

data "oci_core_network_security_groups" "network_security_groups" {
  compartment_id = var.compartment_id
  vcn_id         = data.oci_core_vcns.vcns.virtual_networks[0].id
}

# data "oci_containerengine_node_pool_option" "node_pool_option" {
#   node_pool_option_id = "all"
#   node_pool_k8s_version = var.kubernetes_version
# }

# data "oci_core_images" "images" {
#   compartment_id = var.tenancy_ocid
#   shape          = "VM.Standard.E3.Flex"
# }

# locals {
#   all_images          = data.oci_core_images.images.images
#   all_sources         = data.oci_containerengine_node_pool_option.node_pool_option.sources
#   compartment_images  = [for image in local.all_images : image.id if length(regexall("Oracle-Linux-8.10-20[0-9]*", image.display_name)) > 0]
#   oracle_linux_images = [for source in local.all_sources : source.image_id if length(regexall("Oracle-Linux-8.10-20[0-9]*", source.source_name)) > 0]
#   image_id            = tolist(setintersection(toset(local.compartment_images), toset(local.oracle_linux_images)))[0]
# }

resource "oci_containerengine_cluster" "cluster" {
  name               = var.cluster_name
  compartment_id     = var.compartment_id
  vcn_id             = data.oci_core_vcns.vcns.virtual_networks[0].id
  type               = var.cluster_type
  kubernetes_version = var.kubernetes_version

  endpoint_config {
    subnet_id            = [for subnet in data.oci_core_subnets.subnets.subnets : subnet.id if subnet.display_name == var.cluster_subnet_name][0]
    is_public_ip_enabled = var.is_public_endpoint_enabled
    nsg_ids = flatten([for nsg in data.oci_core_network_security_groups.network_security_groups.network_security_groups :
    [for nsg_name in var.endpoint_nsg_names : nsg.id if nsg.display_name == nsg_name]])
  }

  cluster_pod_network_options {
    cni_type = var.cni_type
  }

  options {
    service_lb_subnet_ids = [for subnet in data.oci_core_subnets.subnets.subnets : subnet.id if subnet.display_name == var.loadbalancer_subnet_name]

    kubernetes_network_config {
      pods_cidr     = var.pods_cidr
      services_cidr = var.services_cidr
    }

    admission_controller_options {
      is_pod_security_policy_enabled = var.is_pod_security_policy_enabled
    }

    dynamic "open_id_connect_token_authentication_config" {
      for_each = var.is_open_id_connect_auth_enabled != null ? [1] : []
      content {
        ca_certificate                  = var.ca_certificate
        client_id                       = var.client_id
        configuration_file              = var.configuration_file
        groups_prefix                   = var.groups_prefix
        is_open_id_connect_auth_enabled = var.is_open_id_connect_auth_enabled
        issuer_url                      = var.issuer_url
        signing_algorithms              = var.signing_algorithms
        username_claim                  = var.username_claim
        username_prefix                 = var.username_prefix
        dynamic "required_claims" {
          for_each = var.required_claims
          content {
            key   = each.key
            value = each.value
          }
        }
      }
    }
  }
}


resource "oci_containerengine_addon" "cert_manager_addon" {
  addon_name                       = "CertManager"
  cluster_id                       = oci_containerengine_cluster.cluster.id
  remove_addon_resources_on_delete = true
  # override_existing                = false
  # version                          = "v1.19.1"
}

resource "oci_containerengine_addon" "metric_server_addon" {
  addon_name                       = "KubernetesMetricsServer"
  cluster_id                       = oci_containerengine_cluster.cluster.id
  remove_addon_resources_on_delete = true
  # override_existing                = false
  # version                          = "v0.8.0"
  depends_on = [oci_containerengine_addon.cert_manager_addon]
}


resource "oci_containerengine_addon" "ingress_controller_addon" {
  addon_name                       = "NativeIngressController"
  cluster_id                       = oci_containerengine_cluster.cluster.id
  remove_addon_resources_on_delete = true
  # override_existing                = false
  # version                          = "v1.4.2"

  configurations {
    key   = "compartmentId"
    value = var.compartment_id
  }

  configurations {
    key   = "loadBalancerSubnetId"
    value = [for subnet in data.oci_core_subnets.subnets.subnets : subnet.id if subnet.display_name == var.loadbalancer_subnet_name][0]
  }
  depends_on = [oci_containerengine_addon.cert_manager_addon]
}

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

resource "oci_containerengine_node_pool" "node_pool" {
  for_each = var.node_pools

  name               = each.key
  cluster_id         = oci_containerengine_cluster.cluster.id
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  node_shape         = each.value.node_shape


  node_shape_config {
    memory_in_gbs = each.value.node_shape_memory_in_gbs
    ocpus         = each.value.node_shape_ocpus
  }

  node_pool_cycling_details {
    cycle_modes             = each.value.cycle_modes
    is_node_cycling_enabled = each.value.is_node_cycling_enabled
    maximum_surge           = each.value.maximum_surge
    maximum_unavailable     = each.value.maximum_unavailable
  }

  dynamic "node_eviction_node_pool_settings" {
    for_each = each.value.eviction_grace_duration != null ? [1] : []
    content {
      eviction_grace_duration              = each.value.eviction_grace_duration
      is_force_action_after_grace_duration = each.value.is_force_action_after_grace_duration
      is_force_delete_after_grace_duration = each.value.is_force_delete_after_grace_duration
    }
  }

  node_config_details {
    size = each.value.node_pool_size
    nsg_ids = flatten([for nsg in data.oci_core_network_security_groups.network_security_groups.network_security_groups :
    [for nsg_name in each.value.node_nsg_names : nsg.id if nsg.display_name == nsg_name]])
    placement_configs {
      subnet_id           = [for subnet in data.oci_core_subnets.subnets.subnets : subnet.id if subnet.display_name == var.worker_subnet_name][0]
      availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[0].name
    }
    node_pool_pod_network_option_details {
      cni_type = each.value.cni_type
    }
  }

  node_source_details {
    image_id    = each.value.image_id
    source_type = each.value.source_type
  }
}