variable "compartment_id" {
  type = string
}

variable "vault_name" {
  type    = string
  default = "dev-vault"
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
  default = {
    "encryption-key" = {
      protection_mode     = "SOFTWARE"
      key_shape_algorithm = "AES"
      key_shape_length    = "32"
    }
  }
}

variable "tags" {
  type    = object({ freeformTags = map(string), definedTags = map(string) })
  default = { "definedTags" = {}, "freeformTags" = { "CreatedBy" = "Terraform" } }
}