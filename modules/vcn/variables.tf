variable "tenancy_ocid" {}

variable "compartment_id" {}

variable "vcn_cidr_blocks" {
  type = list(string)
}

variable "vcn_name" {
  type    = string
  default = "acme-dev-vcn"
}

variable "internet_gateway_enabled" {
  type    = bool
  default = true
}

variable "internet_gateway_name" {
  type    = string
  default = "internet-gateway-0"
}

variable "nat_gateway_name" {
  type    = string
  default = "nat-gateway-0"
}

variable "service_gateway_name" {
  type    = string
  default = "service-gateway-0"
}

variable "service_name" {
  type    = string
  default = "All SIN Services In Oracle Services Network"
}

variable "dhcp_options_name" {
  type    = string
  default = "dhcp-options-0"
}

variable "dhcp_options_type" {
  type    = string
  default = "DomainNameServer"
}

variable "dhcp_options_server_type" {
  type    = string
  default = "VcnLocalPlusInternet"
}

variable "security_lists" {
  type = map(object({
    egress_security_rules = optional(set(object({
      protocol         = string
      destination      = string
      destination_type = optional(string)
      description      = optional(string)
      stateless        = optional(bool, false)

      icmp_options = optional(object({
        type = number
        code = optional(number)
      }))

      tcp_options = optional(object({
        max = number
        min = number
      }))

      udp_options = optional(object({
        max = number
        min = number
      }))
    })))

    ingress_security_rules = optional(set(object({
      protocol    = string
      source      = string
      source_type = optional(string)
      description = optional(string)
      stateless   = optional(bool, false)

      icmp_options = optional(object({
        type = number
        code = optional(number)
      }))

      tcp_options = optional(object({
        max = number
        min = number
      }))

      udp_options = optional(object({
        max = number
        min = number
      }))
    })))
  }))
  nullable = true
  default  = null
}

variable "route_tables" {
  type = map(set(object({
    network_entity_id = string
    description       = optional(string)
    destination       = optional(string)
    destination_type  = optional(string)
  })))
  default = {
    "routetable-KubernetesAPIendpoint" = [
      {
        network_entity_id = "natgw"
        destination       = "0.0.0.0/0"
        destination_type  = "CIDR_BLOCK"
        description       = "Rule for traffic to internet"
      },
      {
        network_entity_id = "svcgw"
        destination       = "all-sin-services-in-oracle-services-network"
        destination_type  = "SERVICE_CIDR_BLOCK"
        description       = "Rule for traffic to OCI services"
      }
    ],
    "routetable-workernodes" = [
      {
        network_entity_id = "natgw"
        destination       = "0.0.0.0/0"
        destination_type  = "CIDR_BLOCK"
        description       = "Rule for traffic to internet"
      },
      {
        network_entity_id = "svcgw"
        destination       = "all-sin-services-in-oracle-services-network"
        destination_type  = "SERVICE_CIDR_BLOCK"
        description       = "Rule for traffic to OCI services"
      }
    ],
    "routetable-loadbalancers" = [
      {
        network_entity_id = "intgw"
        destination       = "0.0.0.0/0"
        destination_type  = "CIDR_BLOCK"
        description       = "Rule for traffic to internet"
      }
    ]
  }
}

variable "subnets" {
  type = map(object({
    cidr_block                = string
    dhcp_options_id           = optional(string)
    prohibit_internet_ingress = optional(bool, false)
    route_table_id            = optional(string)
    security_list_ids         = optional(list(string))
  }))
  default = {
    "KubernetesAPIendpoint" = {
      cidr_block                = "10.0.0.0/30"
      prohibit_internet_ingress = true
      route_table_id            = "routetable-KubernetesAPIendpoint"
      security_list_ids         = ["seclist-KubernetesAPIendpoint"]
    },
    "workernodes" = {
      cidr_block                = "10.0.1.0/24"
      prohibit_internet_ingress = true
      route_table_id            = "routetable-KubernetesAPIendpoint"
      security_list_ids         = ["seclist-KubernetesAPIendpoint"]
    },
    "loadbalancers" = {
      cidr_block        = "10.0.2.0/24"
      route_table_id    = "routetable-KubernetesAPIendpoint"
      security_list_ids = ["seclist-KubernetesAPIendpoint"]
    },
    "bastion" = {
      cidr_block                = "10.0.3.0/24"
      prohibit_internet_ingress = true
      route_table_id            = "routetable-KubernetesAPIendpoint"
      security_list_ids         = ["seclist-KubernetesAPIendpoint"]
    }
  }
}

