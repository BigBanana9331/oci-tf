data "oci_core_services" "services" {}

data "oci_identity_availability_domains" "availability_domains" {
  compartment_id = var.tenancy_ocid
}

resource "oci_core_vcn" "vcn" {
  compartment_id = var.compartment_id
  cidr_blocks    = var.vcn_cidr_blocks
  display_name   = var.vcn_name
}

resource "oci_core_dhcp_options" "dhcp_options" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = var.dhcp_options_name
  options {
    type        = var.dhcp_options_type
    server_type = var.dhcp_options_server_type
  }
}

resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  enabled        = var.internet_gateway_enabled
  display_name   = var.internet_gateway_name
}

resource "oci_core_nat_gateway" "nat_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = var.nat_gateway_name
}

resource "oci_core_service_gateway" "service_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = var.service_gateway_name

  services {
    service_id = data.oci_core_services.services.services[0].id
  }
}

locals {
  gateways = {
    natgw = oci_core_nat_gateway.nat_gateway.id
    svcgw = oci_core_service_gateway.service_gateway.id
    intgw = oci_core_internet_gateway.internet_gateway.id
  }
}

resource "oci_core_security_list" "security_list" {
  for_each = var.security_lists != null ? var.security_lists : {}

  display_name   = each.key
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  dynamic "egress_security_rules" {
    for_each = each.value.egress_security_rules == null ? [] : each.value.egress_security_rules
    content {
      destination      = egress_security_rules.value.destination
      protocol         = egress_security_rules.value.protocol
      description      = egress_security_rules.value.description
      destination_type = egress_security_rules.value.destination_type
      stateless        = egress_security_rules.value.stateless
      dynamic "icmp_options" {
        for_each = egress_security_rules.value.icmp_options == null ? [] : [egress_security_rules.value.icmp_options]
        content {
          type = icmp_options.value.type
          code = icmp_options.value.code
        }
      }

      dynamic "tcp_options" {
        for_each = egress_security_rules.value.tcp_options == null ? [] : [egress_security_rules.value.tcp_options]
        content {
          max = tcp_options.value.max
          min = tcp_options.value.min
        }
      }

      dynamic "udp_options" {
        for_each = egress_security_rules.value.udp_options == null ? [] : [egress_security_rules.value.udp_options]
        content {
          max = udp_options.value.max
          min = udp_options.value.min
        }
      }
    }
  }

  dynamic "ingress_security_rules" {
    for_each = each.value.ingress_security_rules != null ? each.value.ingress_security_rules : []
    content {
      source      = ingress_security_rules.value.source
      protocol    = ingress_security_rules.value.protocol
      description = ingress_security_rules.value.description
      source_type = ingress_security_rules.value.source_type
      stateless   = ingress_security_rules.value.stateless

      dynamic "icmp_options" {
        for_each = ingress_security_rules.value.icmp_options != null ? [ingress_security_rules.value.icmp_options] : []

        content {
          type = icmp_options.value.type
          code = icmp_options.value.code
        }
      }

      dynamic "tcp_options" {
        for_each = ingress_security_rules.value.tcp_options != null ? [ingress_security_rules.value.tcp_options] : []

        content {
          max = tcp_options.value.max
          min = tcp_options.value.min
        }
      }

      dynamic "udp_options" {
        for_each = ingress_security_rules.value.udp_options != null ? [ingress_security_rules.value.udp_options] : []

        content {
          max = udp_options.value.max
          min = udp_options.value.min
        }
      }
    }
  }
}

resource "oci_core_route_table" "route_table" {
  for_each = var.route_tables != null ? var.route_tables : {}

  display_name   = each.key
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  dynamic "route_rules" {
    for_each = each.value != null ? each.value : []
    content {
      network_entity_id = local.gateways[route_rules.value.network_entity_id]
      description       = route_rules.value.description
      destination       = route_rules.value.destination
      destination_type  = route_rules.value.destination_type
    }
  }

  depends_on = [
    oci_core_internet_gateway.internet_gateway,
    oci_core_nat_gateway.nat_gateway,
    oci_core_service_gateway.service_gateway
  ]
}

resource "oci_core_subnet" "subnet" {
  for_each = var.subnets != null ? var.subnets : {}

  display_name              = each.key
  compartment_id            = var.compartment_id
  vcn_id                    = oci_core_vcn.vcn.id
  cidr_block                = each.value.cidr_block
  prohibit_internet_ingress = each.value.prohibit_internet_ingress
  dhcp_options_id           = each.value.dhcp_options_id
  route_table_id            = var.route_tables != null ? oci_core_route_table.route_table[each.value.route_table_id].id : null
  security_list_ids         = var.security_lists != null ? [for sl in each.value.security_list_ids : oci_core_security_list.security_list[sl].id] : []
}

