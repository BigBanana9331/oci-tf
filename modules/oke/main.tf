data "oci_core_services" "services" {}

data "oci_identity_availability_domains" "availability_domains" {
  #Required
  compartment_id = var.tenancy_ocid
}

locals {
  service_ids = [for service in data.oci_core_services.services.services : service.id]
  natgw       = oci_core_nat_gateway.nat_gateway.id
  svcgw       = oci_core_service_gateway.service_gateway.id
  intgw       = oci_core_internet_gateway.internet_gateway.id
}

resource "oci_core_vcn" "vcn" {
  #Required
  compartment_id = var.compartment_id
  cidr_blocks    = var.vcn_cidr_blocks
  display_name   = var.vcn_name
}

resource "oci_core_dhcp_options" "dhcp_options" {
  #Required
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = var.dhcp_options_name
  options {
    type        = var.dhcp_options_type
    server_type = var.dhcp_options_server_type
  }
}

resource "oci_core_internet_gateway" "internet_gateway" {
  #Required
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  enabled        = var.internet_gateway_enabled
  display_name   = var.internet_gateway_name
}

resource "oci_core_nat_gateway" "nat_gateway" {
  #Required
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = var.nat_gateway_name
}

resource "oci_core_service_gateway" "service_gateway" {
  #Required
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = var.service_gateway_name

  dynamic "services" {
    for_each = local.service_ids
    content {
      service_id = services.value
    }
  }
}

resource "oci_core_security_list" "security_list" {
  for_each = var.security_lists

  display_name   = each.key
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  dynamic "egress_security_rules" {
    for_each = each.value.egress_security_rules == null ? [] : each.value.egress_security_rules
    content {
      destination      = each.value.destination
      protocol         = each.value.protocol
      description      = each.value.description
      destination_type = each.value.destination_type
      stateless        = each.value.stateless

      dynamic "icmp_options" {
        for_each = each.value.icmp_options == null ? [] : [each.value.icmp_options]
        content {
          type = each.value.type
          code = each.value.code
        }
      }

      dynamic "tcp_options" {
        for_each = each.value.tcp_options == null ? [] : [each.value.tcp_options]
        content {
          max = each.value.max
          min = each.value.min
        }
      }

      dynamic "udp_options" {
        for_each = each.value.udp_options == null ? [] : [each.value.udp_options]
        content {
          max = each.value.max
          min = each.value.min
        }
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = each.value.ingress_security_rules == null ? [] : each.value.ingress_security_rules

    content {
      source      = each.value.source
      protocol    = each.value.protocol
      description = each.value.description
      source_type = each.value.source_type
      stateless   = each.value.stateless

      dynamic "icmp_options" {
        for_each = each.value.icmp_options == null ? [] : [each.value.icmp_options]

        content {
          type = each.value.type
          code = each.value.code
        }
      }

      dynamic "tcp_options" {
        for_each = each.value.tcp_options == null ? [] : [each.value.tcp_options]

        content {
          max = each.value.max
          min = each.value.min
        }
      }

      dynamic "udp_options" {
        for_each = each.value.udp_options == null ? [] : [each.value.udp_options]

        content {
          max = each.value.max
          min = each.value.min
        }
      }
    }
  }
}

resource "oci_core_route_table" "route_table" {
  for_each = var.route_tables
  #Required
  display_name   = each.key
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  dynamic "route_rules" {
    for_each = each.value
    content {
      network_entity_id = each.value.network_entity_id
      description       = each.value.description
      destination       = each.value.destination
      destination_type  = each.value.destination_type
    }
  }

  depends_on = [
    oci_core_internet_gateway.internet_gateway,
    oci_core_nat_gateway.nat_gateway,
    oci_core_service_gateway.service_gateway
  ]
}

resource "oci_core_subnet" "subnet" {
  for_each = var.subnets

  display_name              = each.key
  compartment_id            = var.compartment_id
  vcn_id                    = oci_core_vcn.vcn.id
  cidr_block                = each.value.cidr_block
  prohibit_internet_ingress = each.value.prohibit_internet_ingress
  dhcp_options_id           = each.value.dhcp_options_id
  route_table_id            = oci_core_route_table.route_table[each.value.route_table_id].id
  security_list_ids         = [for sl in each.value.security_list_ids : oci_core_security_list.security_list[sl].id]
}

resource "oci_containerengine_cluster" "cluster" {
  name               = var.cluster_name
  compartment_id     = var.compartment_id
  vcn_id             = oci_core_vcn.vcn.id
  type               = var.cluster_type
  kubernetes_version = var.kubernetes_version

  endpoint_config {
    subnet_id = oci_core_subnet.subnet["KubernetesAPIendpoint"].id
  }

  options {
    kubernetes_network_config {
      pods_cidr     = var.pods_cidr
      services_cidr = var.services_cidr
    }
    service_lb_subnet_ids = [oci_core_subnet.subnet["loadbalancers"].id]
  }
}

resource "oci_containerengine_node_pool" "test_node_pool" {
  for_each = var.node_pools

  name               = each.key
  cluster_id         = oci_containerengine_cluster.cluster.id
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  node_shape         = each.value.node_shape

  node_config_details {
    size = each.value.node_pool_size
    placement_configs {
      #Required
      subnet_id           = oci_core_subnet.subnet["workernodes"].id
      availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[0].name
    }
  }
}