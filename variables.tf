variable "tenancy_ocid" {
  type = string
}

variable "compartment_ocid" {
  type = string
}

variable "region" {
  type = string
}

variable "environment" {
  type     = string
  nullable = true
  default  = null
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

variable "file_system" {
  nullable = true
  default  = null
  type = object({
    tenancy_ocid     = string
    compartment_id   = string
    vault_name       = string
    key_name         = string
    file_system_name = string
    tags             = object({ freeformTags = map(string), definedTags = map(string) })
  })
}

variable "log_group" {
  nullable = true
  default  = null
  type = object({
    compartment_id        = string
    log_group_name        = string
    key_name              = string
    log_group_description = string
    tags                  = object({ freeformTags = map(string), definedTags = map(string) })
  })
}