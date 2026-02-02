data "oci_identity_availability_domains" "availability_domains" {
  compartment_id = var.tenancy_ocid
}

data "oci_identity_compartment" "compartment" {
  id = var.compartment_id
}

data "oci_core_vcns" "vcns" {
  compartment_id = var.compartment_id
  display_name   = join("-", [var.environment, var.vcn_name])
}

data "oci_core_subnets" "subnets" {
  compartment_id = var.compartment_id
  vcn_id         = data.oci_core_vcns.vcns.virtual_networks[0].id
}

data "oci_core_network_security_groups" "network_security_groups" {
  compartment_id = var.compartment_id
  vcn_id         = data.oci_core_vcns.vcns.virtual_networks[0].id
}

data "oci_containerengine_node_pool_option" "node_pool_option" {
  node_pool_option_id   = var.node_pool_option_id
  node_pool_k8s_version = var.kubernetes_version
  node_pool_os_arch     = var.node_pool_os_arch
  node_pool_os_type     = var.node_pool_os_type
}

locals {
  image_id = [
    for source in data.oci_containerengine_node_pool_option.node_pool_option.sources :
    source.image_id if strcontains(source.source_name, "Gen2-GPU") == false
  ][0]
}

resource "oci_containerengine_cluster" "cluster" {
  name               = join("-", [var.environment, var.cluster_name])
  compartment_id     = var.compartment_id
  vcn_id             = data.oci_core_vcns.vcns.virtual_networks[0].id
  type               = var.cluster_type
  kubernetes_version = var.kubernetes_version

  endpoint_config {
    subnet_id            = [for subnet in data.oci_core_subnets.subnets.subnets : subnet.id if subnet.display_name == join("-", [var.environment, var.cluster_subnet_name])][0]
    is_public_ip_enabled = var.is_public_endpoint_enabled
    nsg_ids = flatten([for nsg in data.oci_core_network_security_groups.network_security_groups.network_security_groups :
    [for nsg_name in var.endpoint_nsg_names : nsg.id if nsg.display_name == join("-", [var.environment, nsg_name])]])
  }

  cluster_pod_network_options {
    cni_type = var.cni_type
  }

  options {
    service_lb_subnet_ids = [for subnet in data.oci_core_subnets.subnets.subnets : subnet.id if subnet.display_name == join("-", [var.environment, var.loadbalancer_subnet_name])]

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

  defined_tags  = var.tags.definedTags
  freeform_tags = var.tags.freeformTags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}

resource "oci_logging_log_group" "log_group" {
  compartment_id = var.compartment_id
  display_name   = join("-", [var.environment, var.log_group.name])
  description    = var.log_group.description

  defined_tags  = var.tags.definedTags
  freeform_tags = var.tags.freeformTags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}

resource "oci_logging_log" "logs" {
  for_each           = var.logs
  log_group_id       = oci_logging_log_groups.log_group.id
  display_name       = join("-", [var.environment, each.key])
  log_type           = each.value.type
  is_enabled         = each.value.is_enabled
  retention_duration = each.value.retention_duration

  dynamic "configuration" {
    for_each = each.value.type != "CUSTOM" ? [1] : []
    content {
      compartment_id = var.compartment_id
      source {
        source_type = each.value.source_type
        service     = each.value.service
        resource    = oci_containerengine_cluster.cluster.id
        category    = each.value.category
        parameters  = each.value.parameters
      }
    }
  }

  defined_tags  = var.tags.definedTags
  freeform_tags = var.tags.freeformTags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }

  depends_on = [oci_containerengine_cluster.cluster, oci_logging_log_group.log_group]
}

resource "oci_identity_dynamic_group" "dynamic_group" {
  compartment_id = var.tenancy_ocid
  description    = var.instance_dynamic_group.description
  matching_rule  = "ANY {instance.compartment.id = '${var.compartment_id}'}"
  name           = join("-", [var.environment, var.instance_dynamic_group.name])

  defined_tags  = var.tags.definedTags
  freeform_tags = var.tags.freeformTags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}

resource "oci_identity_policy" "policy" {
  compartment_id = var.compartment_id
  description    = var.policy.description
  name           = join("-", [var.environment, var.policy.name])

  statements = [
    "Allow any-user to manage load-balancers in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type = 'workload', request.principal.namespace = 'native-ingress-controller-system', request.principal.service_account = 'oci-native-ingress-controller', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow any-user to use virtual-network-family in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type = 'workload', request.principal.namespace = 'native-ingress-controller-system', request.principal.service_account = 'oci-native-ingress-controller', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow any-user to manage cabundles in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type = 'workload', request.principal.namespace = 'native-ingress-controller-system', request.principal.service_account = 'oci-native-ingress-controller', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow any-user to manage cabundle-associations in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type = 'workload', request.principal.namespace = 'native-ingress-controller-system', request.principal.service_account = 'oci-native-ingress-controller', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow any-user to manage leaf-certificates in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type = 'workload', request.principal.namespace = 'native-ingress-controller-system', request.principal.service_account = 'oci-native-ingress-controller', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow any-user to read leaf-certificate-bundles in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type = 'workload', request.principal.namespace = 'native-ingress-controller-system', request.principal.service_account = 'oci-native-ingress-controller', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow any-user to manage leaf-certificate-versions in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type = 'workload', request.principal.namespace = 'native-ingress-controller-system', request.principal.service_account = 'oci-native-ingress-controller', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow any-user to manage certificate-associations in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type = 'workload', request.principal.namespace = 'native-ingress-controller-system', request.principal.service_account = 'oci-native-ingress-controller', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow any-user to read certificate-authorities in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type = 'workload', request.principal.namespace = 'native-ingress-controller-system', request.principal.service_account = 'oci-native-ingress-controller', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow any-user to manage certificate-authority-associations in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type = 'workload', request.principal.namespace = 'native-ingress-controller-system', request.principal.service_account = 'oci-native-ingress-controller', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow any-user to read certificate-authority-bundles in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type = 'workload', request.principal.namespace = 'native-ingress-controller-system', request.principal.service_account = 'oci-native-ingress-controller', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow any-user to read public-ips in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type = 'workload', request.principal.namespace = 'native-ingress-controller-system', request.principal.service_account = 'oci-native-ingress-controller', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow any-user to manage floating-ips in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type = 'workload', request.principal.namespace = 'native-ingress-controller-system', request.principal.service_account = 'oci-native-ingress-controller', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow any-user to manage waf-family in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type = 'workload', request.principal.namespace = 'native-ingress-controller-system', request.principal.service_account = 'oci-native-ingress-controller', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow any-user to read cluster-family in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type = 'workload', request.principal.namespace = 'native-ingress-controller-system', request.principal.service_account = 'oci-native-ingress-controller', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow any-user to use tag-namespaces in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type = 'workload', request.principal.namespace = 'native-ingress-controller-system', request.principal.service_account = 'oci-native-ingress-controller', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow any-user to manage cluster-node-pools in compartment ${data.oci_identity_compartment.compartment.name} where ALL {request.principal.type='workload', request.principal.namespace ='kube-system', request.principal.service_account = 'cluster-autoscaler', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow any-user to manage instance-family in compartment ${data.oci_identity_compartment.compartment.name} where ALL {request.principal.type='workload', request.principal.namespace ='kube-system', request.principal.service_account = 'cluster-autoscaler', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow any-user to use subnets in compartment ${data.oci_identity_compartment.compartment.name} where ALL {request.principal.type='workload', request.principal.namespace ='kube-system', request.principal.service_account = 'cluster-autoscaler', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow any-user to read virtual-network-family in compartment ${data.oci_identity_compartment.compartment.name} where ALL {request.principal.type='workload', request.principal.namespace ='kube-system', request.principal.service_account = 'cluster-autoscaler', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow any-user to use vnics in compartment ${data.oci_identity_compartment.compartment.name} where ALL {request.principal.type='workload', request.principal.namespace ='kube-system', request.principal.service_account = 'cluster-autoscaler', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow any-user to inspect compartments in compartment ${data.oci_identity_compartment.compartment.name} where ALL {request.principal.type='workload', request.principal.namespace ='kube-system', request.principal.service_account = 'cluster-autoscaler', request.principal.cluster_id = '${oci_containerengine_cluster.cluster.id}'}",
    "Allow dynamic-group dev-nodes-dg to use log-content in compartment ${data.oci_identity_compartment.compartment.name}" # managed nodes log
  ]

  defined_tags  = var.tags.definedTags
  freeform_tags = var.tags.freeformTags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }

  depends_on = [oci_containerengine_cluster.cluster]
}

resource "oci_containerengine_addon" "cert_manager_addon" {
  addon_name                       = "CertManager"
  cluster_id                       = oci_containerengine_cluster.cluster.id
  remove_addon_resources_on_delete = true
}

resource "oci_containerengine_addon" "ingress_controller_addon" {
  addon_name                       = "NativeIngressController"
  cluster_id                       = oci_containerengine_cluster.cluster.id
  remove_addon_resources_on_delete = true

  configurations {
    key   = "compartmentId"
    value = var.compartment_id
  }

  configurations {
    key   = "authType"
    value = "workloadIdentity"
  }

  configurations {
    key   = "loadBalancerSubnetId"
    value = [for subnet in data.oci_core_subnets.subnets.subnets : subnet.id if subnet.display_name == join("-", [var.environment, var.loadbalancer_subnet_name])][0]
  }

  depends_on = [oci_containerengine_addon.cert_manager_addon]
}

resource "oci_containerengine_node_pool" "node_pool" {
  for_each = var.node_pools

  name               = join("-", [var.environment, each.key])
  cluster_id         = oci_containerengine_cluster.cluster.id
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  node_shape         = each.value.node_shape
  node_metadata      = each.value.node_metadata

  dynamic "initial_node_labels" {
    for_each = each.value.initial_node_labels != null ? each.value.initial_node_labels : {}
    content {
      key   = initial_node_labels.key
      value = initial_node_labels.value
    }
  }

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
    size                                = each.value.node_pool_size
    is_pv_encryption_in_transit_enabled = each.value.is_pv_encryption_in_transit_enabled
    nsg_ids = flatten([for nsg in data.oci_core_network_security_groups.network_security_groups.network_security_groups :
    [for nsg_name in each.value.node_nsg_names : nsg.id if nsg.display_name == join("-", [var.environment, nsg_name])]])

    placement_configs {
      subnet_id           = [for subnet in data.oci_core_subnets.subnets.subnets : subnet.id if subnet.display_name == join("-", [var.environment, var.worker_subnet_name])][0]
      availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[0].name
    }

    node_pool_pod_network_option_details {
      cni_type = each.value.cni_type
    }

    defined_tags  = var.tags.definedTags
    freeform_tags = var.tags.freeformTags
  }

  node_source_details {
    image_id    = local.image_id
    source_type = each.value.source_type
  }

  defined_tags  = var.tags.definedTags
  freeform_tags = var.tags.freeformTags

  lifecycle {
    ignore_changes = [
      defined_tags,
      freeform_tags,
      node_config_details[0].defined_tags,
      node_config_details[0].freeform_tags,
    ]
  }
}

resource "oci_logging_unified_agent_configuration" "unified_agent_configuration" {
  compartment_id = var.compartment_id
  description    = var.unified_agent_configuration.description
  display_name   = join("-", [var.environment, var.unified_agent_configuration.name])
  is_enabled     = var.unified_agent_configuration.is_enabled

  service_configuration {
    configuration_type = var.unified_agent_configuration.configuration_type
    destination {
      log_object_id = [for log in oci_logging_log.logs : log.id if log.display_name == join("-", [var.environment, var.unified_agent_configuration.log_object_name])][0]
    }

    sources {
      name        = join("-", [var.environment, var.unified_agent_configuration.source.name])
      source_type = var.unified_agent_configuration.source.source_type
      paths       = var.unified_agent_configuration.source.paths
      parser {
        parser_type = var.unified_agent_configuration.source.parser_type
      }
    }
  }

  group_association {
    group_list = [oci_identity_dynamic_group.dynamic_group.id]
  }

  defined_tags  = var.tags.definedTags
  freeform_tags = var.tags.freeformTags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}

resource "oci_containerengine_addon" "metric_server_addon" {
  addon_name                       = "KubernetesMetricsServer"
  cluster_id                       = oci_containerengine_cluster.cluster.id
  remove_addon_resources_on_delete = true

  depends_on = [oci_containerengine_addon.cert_manager_addon]
}

resource "oci_containerengine_addon" "auto_scaler_addon" {
  count                            = var.autoscaler.is_enabled ? 1 : 0
  addon_name                       = "ClusterAutoscaler"
  cluster_id                       = oci_containerengine_cluster.cluster.id
  remove_addon_resources_on_delete = true

  configurations {
    key   = "authType"
    value = "workload"
  }

  configurations {
    key   = "nodes"
    value = join(", ", formatlist("${var.autoscaler.min_node}:${var.autoscaler.max_node}:%s", [for nodepool in oci_containerengine_node_pool.node_pool : nodepool.id]))
  }

  depends_on = [oci_containerengine_node_pool.node_pool]
}