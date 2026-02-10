terraform {
  required_version = "~> 1.14"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.0"
    }
  }
}

variable "tenancy_ocid" {
  type = string
}

variable "compartment_id" {
  type = string
}

variable "tags" {
  type    = object({ freeformTags = map(string), definedTags = map(string) })
  default = { "definedTags" = {}, "freeformTags" = { "CreatedBy" = "Terraform" } }
}

variable "policies" {
  type = map(string)
  default = {
    # "netpol"     = "Networking policy for OKE"
    # "secpol"     = "Security policy for OKE"
    # "computepol" = "Compute policy for OKE"
    logpol = "Policy for instances node group logging"
  }
}

variable "environment" {
  type = string
}

variable "vcn_name" {
  type    = string
  default = "vcn"
}

variable "subnet_id" {
  type = string
}

variable "nsg_ids" {
  type    = set(string)
  default = []
}

variable "availability_domain" {
  type = string
}

variable "shape_name" {
  type    = string
  default = "MySQL.2"
}

variable "mysql_version" {
  type     = string
  nullable = true
  default  = null
}

variable "access_mode" {
  type     = string
  nullable = true
  default  = "UNRESTRICTED"
}

variable "database_mode" {
  type    = string
  default = "READ_WRITE"
}

variable "crash_recovery" {
  type     = string
  nullable = true
  default  = "ENABLED"
}

variable "database_management" {
  type     = string
  nullable = true
  default  = "DISABLED"
}

variable "port" {
  type    = number
  default = 3306
}

variable "port_x" {
  type    = number
  default = 33060
}

# variable "hostname_label" {
#   type    = string
#   default = "mysql"
# }

variable "ip_address" {
  type     = string
  nullable = true
  default  = null
}

variable "admin_username" {
  type    = string
  default = "admin"
}

variable "admin_password" {
  type      = string
  sensitive = true
}

# variable "vault_name" {
#   type    = string
#   default = "dev-vault"
# }

# variable "admin_password_secret_name" {
#   type    = string
#   default = "dev-mysql-admin-password"
# }

variable "key_generation_type" {
  type    = string
  default = "BYOK" # BYOK/SYSTEM
}

variable "kms_key_id" {
  type     = string
  nullable = true
  default  = null
}

variable "certificate_generation_type" {
  type    = string
  default = "SYSTEM"
}

variable "certificate_id" {
  type     = string
  nullable = true
  default  = null
}

variable "display_name" {
  type    = string
  default = "mysql"
}

variable "description" {
  type    = string
  default = "MySQL Database Service"
}

variable "data_storage_size_in_gb" {
  type    = string
  default = "50"
}


variable "is_highly_available" {
  type    = bool
  default = false
}

variable "data_storage" {
  type = object({
    is_auto_expand_storage_enabled = optional(bool)
    max_storage_size_in_gbs        = optional(string)
  })
  default = {
    is_auto_expand_storage_enabled = false
    max_storage_size_in_gbs        = "100"
  }
}

variable "policy" {
  type = object({
    name        = string
    description = string
  })
  default = {
    description = "policy created by terraform"
    name        = "mysql-policy"
  }
}

variable "backup_policy" {
  type = object({
    is_enabled        = optional(bool)
    retention_in_days = optional(number)
    window_start_time = optional(string)
    soft_delete       = optional(string)
    pitr_enabled      = optional(bool)
  })
  default = {
    is_enabled        = false
    retention_in_days = 1
    window_start_time = "01:00-00:00"
  }
}

variable "deletion_policy" {
  type = object({
    automatic_backup_retention = optional(string)
    final_backup               = optional(string)
    is_delete_protected        = optional(bool)
  })
  default = {
    automatic_backup_retention = "DELETE"
    final_backup               = "SKIP_FINAL_BACKUP"
    is_delete_protected        = "false"
  }
}

variable "read_endpoint" {
  type = object({
    exclude_ips    = optional(list(string))
    is_enabled     = optional(bool)
    hostname_label = optional(string)
    ip_address     = optional(string)
  })
  default = {
    is_enabled = false
  }
}

variable "maintenance" {
  type = object({
    window_start_time         = string
    maintenance_schedule_type = optional(string)
    version_preference        = optional(string)
    version_track_preference  = optional(string)
  })
  default = {
    window_start_time         = "sun 01:00"
    maintenance_schedule_type = "REGULAR"
    version_preference        = "OLDEST"
    version_track_preference  = "FOLLOW"
  }
}

variable "database_console" {
  type = object({
    status = string
    port   = optional(number)
  })
  default = {
    status = "DISABLED"
    port   = "8443"
  }
}

variable "rest" {
  type = object({
    configuration = string
    port          = optional(number)
  })
  default = {
    configuration = "DISABLED"
    port          = "443"
  }
}