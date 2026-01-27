terraform {
  required_version = ">= 1.5.7"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "7.31.0"
    }
  }
}



variable "compartment_id" {
  type = string
}

variable "vault_name" {
  type     = string
  nullable = true
  default  = "dev-vault"
}

variable "key_name" {
  type     = string
  nullable = true
  default  = "encryption-key"
}

variable "queue_dead_letter_queue_delivery_count" {
  type    = number
  default = 10
}

variable "queue_name" {
  type    = string
  default = "dev-queue"
}

variable "queue_retention_in_seconds" {
  type    = number
  default = 10
}

variable "queue_timeout_in_seconds" {
  type    = number
  default = 10
}

variable "queue_visibility_in_seconds" {
  type    = number
  default = 10
}

variable "queue_channel_consumption_limit" {
  type    = number
  default = 10
}

variable "purge_type" {
  type    = string
  default = "NORMAL"
}

variable "purge_trigger" {
  type    = number
  default = 1
}

variable "tags" {
  type    = object({ freeformTags = map(string), definedTags = map(string) })
  default = { "definedTags" = {}, "freeformTags" = { "CreatedBy" = "Terraform" } }
}