# =============================================================================
# Core OCI Configuration Variables
# =============================================================================

variable "compartment_ocid" {
  type        = string
  description = "The OCID of the compartment where resources will be created"

  validation {
    condition     = can(regex("^ocid1\\.compartment\\.", var.compartment_ocid))
    error_message = "The compartment_ocid must be a valid OCI compartment OCID."
  }
}

variable "tenancy_ocid" {
  type        = string
  description = "The OCID of the tenancy"

  validation {
    condition     = can(regex("^ocid1\\.tenancy\\.", var.tenancy_ocid))
    error_message = "The tenancy_ocid must be a valid OCI tenancy OCID."
  }
}

variable "region" {
  type        = string
  description = "The OCI region where resources will be provisioned (e.g., ap-singapore-1, us-ashburn-1)"

  validation {
    condition     = can(regex("^[a-z]{2,4}-[a-z]+-[0-9]+$", var.region))
    error_message = "The region must be a valid OCI region identifier (e.g., ap-singapore-1)."
  }
}

variable "oci_config_profile" {
  type        = string
  description = "The OCI CLI configuration profile name to use for authentication"
  default     = "DEFAULT"
}

variable "environment" {
  type        = string
  description = "The deployment environment (dev, staging, prod)"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "app_name" {
  type        = string
  description = "The application name used for resource naming conventions"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.app_name))
    error_message = "The app_name must start with a letter, contain only lowercase letters, numbers, and hyphens, and be 2-21 characters long."
  }
}

variable "tags" {
  type        = object({ freeformTags = map(string), definedTags = map(string) })
  description = "Resource tags for cost tracking and organization"
  default = {
    definedTags  = {}
    freeformTags = { "CreatedBy" = "Terraform" }
  }
}

# =============================================================================
# VCN Configuration
# =============================================================================

variable "vcns" {
  description = "Map of VCN configurations including CIDR blocks, route tables, subnets, and NSGs"
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

# =============================================================================
# API Gateway Configuration
# =============================================================================

variable "api_gateway" {
  description = "API Gateway configuration for exposing services"
  nullable    = true
  default     = null
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

# =============================================================================
# Bastion Configuration
# =============================================================================

variable "bastion" {
  description = "Bastion host configuration for secure access to private resources"
  nullable    = true
  default     = null
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

# =============================================================================
# File Storage Configuration
# =============================================================================

variable "file_system" {
  description = "OCI File Storage configuration for shared file systems"
  nullable    = true
  default     = null
  type = object({
    tenancy_ocid     = string
    compartment_id   = string
    vault_name       = string
    key_name         = string
    file_system_name = string
    tags             = object({ freeformTags = map(string), definedTags = map(string) })
  })
}

# =============================================================================
# Logging Configuration
# =============================================================================

variable "log_group" {
  description = "OCI Logging service configuration for centralized log management"
  nullable    = true
  default     = null
  type = object({
    compartment_id        = string
    log_group_name        = string
    key_name              = string
    log_group_description = string
    tags                  = object({ freeformTags = map(string), definedTags = map(string) })
  })
}