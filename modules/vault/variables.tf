terraform {
  required_version = ">= 1.5.7"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "7.31.0"
    }
  }
}

variable "tags" {
  type    = object({ freeformTags = map(string), definedTags = map(string) })
  default = { "definedTags" = {}, "freeformTags" = { "CreatedBy" = "Terraform" } }
}

variable "compartment_id" {
  type = string
}

variable "region" {
  type = string
}

variable "vault_name" {
  type    = string
  default = "dev-vault"
}

variable "vault_type" {
  type    = string
  default = "DEFAULT" # DEFAULT, VIRTUAL_PRIVATE
}

variable "master_keys" {
  type = map(object({
    algorithm                 = string
    length                    = number
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
      protection_mode = "SOFTWARE"
      algorithm       = "AES"
      length          = 32
    }
    "signing-key" = {
      protection_mode = "SOFTWARE"
      algorithm       = "RSA"
      length          = 2048
    }
  }
}

variable "secrets" {
  type = map(object({
    description            = optional(string)
    metadata               = optional(map(string))
    enable_auto_generation = optional(bool)
    key_name               = optional(string, "master-key")
    generation_template    = optional(string)
    generation_type        = optional(string)
    passphrase_length      = optional(number)
    secret_template        = optional(string)
  }))
  default = {
    "dev-mysql-admin-password" = {
      description            = "MySQL admin password"
      enable_auto_generation = true
      generation_template    = "DBAAS_DEFAULT_PASSWORD"
      generation_type        = "PASSPHRASE"
      passphrase_length      = 24
    }
    "dev-nodepool-ssh-key" = {
      description            = "Nodepool instnaces SSH key"
      enable_auto_generation = true
      generation_template    = "RSA_2048"
      generation_type        = "SSH_KEY"
    }
  }
}

