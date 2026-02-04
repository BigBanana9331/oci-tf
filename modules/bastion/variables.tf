terraform {
  required_version = "~> 1.14"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.30"
    }
  }
}

variable "environment" {
  type = string
}

variable "app_name" {
  type     = string
  nullable = true
  default  = null
}

variable "compartment_id" {
  type = string
}

variable "tags" {
  type    = object({ freeformTags = map(string), definedTags = map(string) })
  default = { "definedTags" = {}, "freeformTags" = { "CreatedBy" = "Terraform" } }
}

variable "vcn_name" {
  type    = string
  default = "vcn"
}

variable "subnet_name" {
  type    = string
  default = "subnet-bastion"
}

variable "bastion_name" {
  type    = string
  default = "bastion-0"
}

variable "bastion_type" {
  type    = string
  default = "STANDARD"
}

variable "dns_proxy_status" {
  type     = bool
  nullable = true
  default  = null
}

variable "max_session_ttl_in_seconds" {
  type    = number
  default = 3600
}

variable "client_cidr_block_allow_list" {
  type    = list(string)
  default = ["0.0.0.0/0"]
  validation {
    condition     = alltrue([for cidr in var.client_cidr_block_allow_list : can(cidrhost(cidr, 32))])
    error_message = "Must be valid IPv4 CIDR."
  }
}