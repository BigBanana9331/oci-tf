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

variable "buckets" {
  type    = set(string)
  default = ["dev-objectstorage-fe", "dev-objectstorage-be"]
}

variable "tags" {
  type    = object({ freeformTags = map(string), definedTags = map(string) })
  default = { "definedTags" = {}, "freeformTags" = { "CreatedBy" = "Terraform" } }
}