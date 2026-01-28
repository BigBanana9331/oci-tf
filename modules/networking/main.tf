data "oci_core_services" "services" {}

locals {
  nsg_rules = flatten([
    for nsg, rules in var.nsgs : flatten([
      for idx, rule in rules :
      {
        nsg_name         = nsg
        direction        = rule.direction
        protocol         = rule.protocol
        source           = rule.source
        destination      = rule.destination
        destination_type = rule.destination_type
        source_type      = rule.source_type
        stateless        = rule.stateless
        description      = rule.description
        icmp_options     = rule.icmp_options
        tcp_options      = rule.tcp_options
        udp_options      = rule.udp_options
      }
    ])
  ])

  network_entity_ids = {
    # natgw = oci_core_nat_gateway.nat_gateway.id
    svcgw = oci_core_service_gateway.service_gateway.id
  }

  seclists = {
    for sl_name, sl_res in oci_core_security_list.security_lists :
    sl_name => sl_res.id
  }

  route_tables = {
    for rt_name, rt_res in oci_core_route_table.route_tables :
    rt_name => rt_res.id
  }

  nsgs = {
    for nsg_name, nsg_res in oci_core_network_security_group.network_security_groups :
    nsg_name => nsg_res.id
  }

  subnets = {
    for sn_name, sn_res in oci_core_subnet.subnets :
    sn_name => sn_res.id
  }
}

resource "oci_core_vcn" "vcn" {
  compartment_id = var.compartment_id
  cidr_blocks    = var.vcn_cidr_blocks
  display_name   = var.vcn_name

  # tags
  defined_tags  = var.tags.definedTags
  freeform_tags = var.tags.freeformTags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}

# resource "oci_core_dhcp_options" "dhcp_options" {
#   compartment_id = var.compartment_id
#   vcn_id         = oci_core_vcn.vcn.id
#   display_name   = var.dhcp_options_name

#   options {
#     type        = var.dhcp_options_type
#     server_type = var.dhcp_options_server_type
#   }

#   # tags
#   defined_tags  = var.tags.definedTags
#   freeform_tags = var.tags.freeformTags

#   lifecycle {
#     ignore_changes = [defined_tags, freeform_tags]
#   }
# }

# resource "oci_core_nat_gateway" "nat_gateway" {
#   compartment_id = var.compartment_id
#   vcn_id         = oci_core_vcn.vcn.id
#   display_name   = var.nat_gateway_name

#   # tags
#   defined_tags  = var.tags.definedTags
#   freeform_tags = var.tags.freeformTags

#   lifecycle {
#     ignore_changes = [defined_tags, freeform_tags]
#   }
# }

resource "oci_core_service_gateway" "service_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = var.service_gateway_name

  services {
    service_id = data.oci_core_services.services.services[0].id
  }

  # tags
  defined_tags  = var.tags.definedTags
  freeform_tags = var.tags.freeformTags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}

resource "oci_core_security_list" "security_lists" {
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

  # tags
  defined_tags  = var.tags.definedTags
  freeform_tags = var.tags.freeformTags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}

resource "oci_core_network_security_group" "network_security_groups" {
  for_each       = var.nsgs != null ? var.nsgs : {}
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = each.key

  # tags
  defined_tags  = var.tags.definedTags
  freeform_tags = var.tags.freeformTags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}

resource "oci_core_network_security_group_security_rule" "network_security_group_security_rule" {
  for_each = { for idx, rule in local.nsg_rules : "${rule.nsg_name}-${idx}" => rule }

  network_security_group_id = oci_core_network_security_group.network_security_groups[each.value.nsg_name].id
  direction                 = each.value.direction
  protocol                  = each.value.protocol
  source                    = each.value.source
  destination               = each.value.destination
  destination_type          = each.value.destination_type
  source_type               = each.value.source_type
  stateless                 = each.value.stateless
  description               = each.value.description

  dynamic "icmp_options" {
    for_each = each.value.icmp_options != null ? [each.value.icmp_options] : []
    content {
      type = icmp_options.value.type
      code = icmp_options.value.code
    }
  }

  dynamic "tcp_options" {
    for_each = each.value.tcp_options != null ? [each.value.tcp_options] : []
    content {
      dynamic "destination_port_range" {
        for_each = tcp_options.value.destination_port_range != null ? [tcp_options.value.destination_port_range] : []
        content {
          max = destination_port_range.value.max
          min = destination_port_range.value.min
        }
      }
      dynamic "source_port_range" {
        for_each = tcp_options.value.source_port_range != null ? [tcp_options.value.source_port_range] : []
        content {
          max = source_port_range.value.max
          min = source_port_range.value.min
        }
      }
    }
  }
  dynamic "udp_options" {
    for_each = each.value.udp_options != null ? [each.value.udp_options] : []
    content {
      dynamic "destination_port_range" {
        for_each = udp_options.value.destination_port_range != null ? [udp_options.value.destination_port_range] : []
        content {
          max = destination_port_range.value.max
          min = destination_port_range.value.min
        }
      }
      dynamic "source_port_range" {
        for_each = udp_options.value.source_port_range != null ? [udp_options.value.source_port_range] : []
        content {
          max = source_port_range.value.max
          min = source_port_range.value.min
        }
      }
    }
  }
}

resource "oci_core_route_table" "route_tables" {
  for_each = var.route_tables != null ? var.route_tables : {}

  display_name   = each.key
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  dynamic "route_rules" {
    for_each = each.value != null ? each.value : []
    content {
      network_entity_id = local.network_entity_ids[route_rules.value.network_entity_name]
      description       = route_rules.value.description
      destination       = route_rules.value.destination
      destination_type  = route_rules.value.destination_type
    }
  }

  # tags
  defined_tags  = var.tags.definedTags
  freeform_tags = var.tags.freeformTags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }

  depends_on = [
    # oci_core_nat_gateway.nat_gateway,
    oci_core_service_gateway.service_gateway
  ]
}

resource "oci_core_subnet" "subnets" {
  for_each = var.subnets != null ? var.subnets : {}

  display_name               = each.key
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn.id
  cidr_block                 = each.value.cidr_block
  prohibit_internet_ingress  = each.value.prohibit_internet_ingress
  prohibit_public_ip_on_vnic = each.value.prohibit_public_ip_on_vnic
  route_table_id             = local.route_tables[each.value.route_table_name]
  # dhcp_options_id            = oci_core_dhcp_options.dhcp_options.id
  # security_list_ids          = [for sl in each.value.security_list_names : local.seclists[sl]]

  # tags
  defined_tags  = var.tags.definedTags
  freeform_tags = var.tags.freeformTags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags, security_list_ids, dhcp_options_id]
  }
}