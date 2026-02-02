variable "config_file_profile" {
  type = string
}

variable "compartment_ocid" {
  type = string
}

variable "environment" {
  type = string
}

variable "app_name" {
  type    = string
  default = ""
}

variable "bastion" {
  nullable = true
  default  = null
  type = object({
    vcn_name                   = string
    subnet_name                = string
    bastion_name               = string
    max_session_ttl_in_seconds = number
  })
}