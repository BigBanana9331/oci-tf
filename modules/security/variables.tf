variable "compartment_id" {}

variable "vault_name" {
  type    = string
  default = "tf-vault-0"
}

variable "vault_type" {
  type    = string
  default = "DEFAULT" # default = ["DEFAULT", "VIRTUAL_PRIVATE"]
}

variable "keys" {
  type = map(object({
    key_shape_algorithm       = string
    key_shape_length          = string
    protection_mode           = optional(string)
    is_auto_rotation_enabled  = optional(bool)
    last_rotation_message     = optional(string)
    last_rotation_status      = optional(string)
    rotation_interval_in_days = optional(number)
    time_of_last_rotation     = optional(string)
    time_of_next_rotation     = optional(string)
    time_of_schedule_start    = optional(string)
  }))
  default = {}
}

variable "defined_tags" {
  type = map(string)
  default = {
    "AutoTagging.AppName"   = "Tuntas"
    "AutoTagging.CreatedBy" = "Terraform"
  }
}