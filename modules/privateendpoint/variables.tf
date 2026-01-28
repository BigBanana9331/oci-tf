terraform {
  required_version = ">= 1.5.7"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.30"
    }
  }
}


variable "compartment_id" {
  type = string
}

variable "tags" {
  type    = object({ freeformTags = map(string), definedTags = map(string) })
  default = { "definedTags" = {}, "freeformTags" = { "CreatedBy" = "Terraform" } }
}

variable "private_endpoint" {
  type = object({
    vcn_name                                   = string
    subnet_name                                = string
    name                                       = string
    description                                = optional(string)
    nsg_id_list                                = optional(list(string))
    dns_zones                                  = optional(list(string))
    is_used_with_configuration_source_provider = optional(bool)
  })

  default = {
    name        = "dev-rms-pe"
    vcn_name    = "dev-vcn"
    subnet_name = "dev-subnet-bastion"
    nsg_id_list = ["dev-nsg-bastion"]
  }
}