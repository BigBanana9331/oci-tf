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

# resource "oci_core_security_list" "security_list" {
#   for_each = var.security_lists != null ? var.security_lists : []

#   display_name   = each.key
#   compartment_id = var.compartment_id
#   vcn_id         = oci_core_vcn.vcn.id

#   dynamic "egress_security_rules" {
#     for_each = each.value.egress_security_rules == null ? [] : each.value.egress_security_rules
#     content {
#       destination      = each.value.destination
#       protocol         = each.value.protocol
#       description      = each.value.description
#       destination_type = each.value.destination_type
#       stateless        = each.value.stateless

#       dynamic "icmp_options" {
#         for_each = each.value.icmp_options == null ? [] : [each.value.icmp_options]
#         content {
#           type = each.value.type
#           code = each.value.code
#         }
#       }

#       dynamic "tcp_options" {
#         for_each = each.value.tcp_options == null ? [] : [each.value.tcp_options]
#         content {
#           max = each.value.max
#           min = each.value.min
#         }
#       }

#       dynamic "udp_options" {
#         for_each = each.value.udp_options == null ? [] : [each.value.udp_options]
#         content {
#           max = each.value.max
#           min = each.value.min
#         }
#       }
#     }
#   }

#   dynamic "ingress_security_rules" {
#     for_each = each.value.ingress_security_rules == null ? [] : each.value.ingress_security_rules

#     content {
#       source      = each.value.source
#       protocol    = each.value.protocol
#       description = each.value.description
#       source_type = each.value.source_type
#       stateless   = each.value.stateless

#       dynamic "icmp_options" {
#         for_each = each.value.icmp_options == null ? [] : [each.value.icmp_options]

#         content {
#           type = each.value.type
#           code = each.value.code
#         }
#       }

#       dynamic "tcp_options" {
#         for_each = each.value.tcp_options == null ? [] : [each.value.tcp_options]

#         content {
#           max = each.value.max
#           min = each.value.min
#         }
#       }

#       dynamic "udp_options" {
#         for_each = each.value.udp_options == null ? [] : [each.value.udp_options]

#         content {
#           max = each.value.max
#           min = each.value.min
#         }
#       }
#     }
#   }
# }

resource "oci_core_route_table" "route_table" {
  for_each = var.route_tables != null ? var.route_tables : {}

  display_name   = each.key
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  dynamic "route_rules" {
    for_each = each.value
    content {
      network_entity_id = local.gateways[route_rules.network_entity_id]
      description       = route_rules.description
      destination       = route_rules.destination
      destination_type  = route_rules.destination_type
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
  route_table_id            = oci_core_route_table.route_table[each.value.route_table_id].id
  security_list_ids         = []
  # security_list_ids         = [for sl in each.value.security_list_ids : oci_core_security_list.security_list[sl].id]
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

