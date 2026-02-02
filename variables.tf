variable "compartment_ocid" {
  type = string
}

variable "tenancy_ocid" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "app_name" {
  type = string
}

variable "tags" {
  type    = object({ freeformTags = map(string), definedTags = map(string) })
  default = { "definedTags" = {}, "freeformTags" = { "CreatedBy" = "Terraform" } }
}

variable "vcns" {
  type = map(object({
    cidr_blocks = list(string)
    route_tables = map(set(object({
      network_entity_name = string
      description         = optional(string)
      destination         = optional(string)
      destination_type    = optional(string)
    })))
    subnets = map(object({
      cidr_block                 = string
      dhcp_options_name          = optional(string)
      prohibit_internet_ingress  = optional(bool)
      prohibit_public_ip_on_vnic = optional(bool, true)
      route_table_name           = optional(string)
      dhcp_options_id            = optional(string)
      security_list_names        = optional(list(string))
    }))
    nsgs = map(list(object({
      direction        = string
      protocol         = string
      source           = optional(string)
      destination      = optional(string)
      destination_type = optional(string)
      source_type      = optional(string)
      stateless        = optional(bool)
      description      = optional(string)

      icmp_options = optional(object({
        type = optional(number)
        code = optional(number)
      }))

      tcp_options = optional(object({
        destination_port_range = optional(object({
          max = optional(number)
          min = optional(number)
        }))
        source_port_range = optional(object({
          max = optional(number)
          min = optional(number)
        }))
      }))

      udp_options = optional(object({
        destination_port_range = optional(object({
          max = optional(number)
          min = optional(number)
        }))
        source_port_range = optional(object({
          max = optional(number)
          min = optional(number)
        }))
      }))
    })))
  }))
}

variable "api_gateway" {
  nullable = true
  default  = null
  type = object({
    compartment_id = string
    vcn_name       = string
    subnet_name    = string
    gateway_name   = string
    endpoint_type  = string
    ip_mode        = string
    nsg_names      = list(string)
    tags           = object({ freeformTags = map(string), definedTags = map(string) })
  })
}

variable "bastion" {
  nullable = true
  default  = null
  type = object({
    compartment_id               = string
    vcn_name                     = string
    subnet_name                  = string
    bastion_name                 = string
    bastion_type                 = string
    dns_proxy_status             = bool
    max_session_ttl_in_seconds   = number
    client_cidr_block_allow_list = list(string)
    tags                         = object({ freeformTags = map(string), definedTags = map(string) })
  })
}