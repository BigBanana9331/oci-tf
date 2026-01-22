variable "tenancy_ocid" {}

variable "compartment_id" {}

variable "vcn_name" {
  type    = string
  default = "tf-acme-dev-vcn"
}

variable "subnet_name" {
  type    = string
  default = "database"
}

variable "nsg_names" {
  type    = set(string)
  default = ["nsg-dbs"]
}

variable "shape_name" {
  type    = string
  default = "MySQL.VM.Standard.E4.4.64GB"
}

variable "mysql_version" {
  type     = string
  nullable = true
  default  = null
}

variable "access_mode" {
  type     = string
  nullable = true
  default  = null
}

variable "crash_recovery" {
  type     = string
  nullable = true
  default  = null
}

variable "database_management" {
  type     = string
  nullable = true
  default  = null
}

variable "admin_username" {
  type    = string
  default = "admin"
}

variable "vault_name" {
  type    = string
  default = "vault-0"
}

variable "admin_password" {
  type = object({
    display_name = string
    description  = optional(string)
    metadata     = optional(map(string))
    content_type = optional(string, "BASE64")
    name         = optional(string)
    stage        = optional(string)
  })
  default = {
    display_name = "HeatWave-DBSystem-admin-password"
  }
}

variable "key_generation_type" {
  type     = string
  nullable = true
  default  = null
}

variable "key_name" {
  type     = string
  nullable = true
  default  = null
}

variable "display_name" {
  type    = string
  default = "HeatWave-DBSystem"
}

variable "description" {
  type    = string
  default = "MySQL Database Service"
}

variable "data_storage_size_in_gb" {
  type    = string
  default = "50"
}

variable "is_auto_expand_storage_enabled" {
  type    = bool
  default = false
}

variable "max_storage_size_in_gbs" {
  type    = string
  default = "4000"
}

variable "is_highly_available" {
  type    = bool
  default = false
}

variable "backup_policy" {
  type = object({
    is_enabled        = string
    retention_in_days = string
    window_start_time = string
  })
  default = {
    is_enabled        = "false"
    retention_in_days = "7"
    window_start_time = "01:00-00:00"
  }
}

variable "maintenance_window_start_time" {
  type    = string
  default = "sun 01:00"
}

variable "database_console" {
  type = object({
    status = string
    port   = optional(number)
  })
  default  = null
  nullable = true
}

variable "defined_tags" {
  type = map(string)
  default = {
    "AutoTagging.AppName"   = "Tuntas"
    "AutoTagging.CreatedBy" = "Terraform"
  }
}