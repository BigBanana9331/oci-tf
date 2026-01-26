variable "compartment_id" {
  type = string
}

variable "tags" {
  type    = object({ freeformTags = map(string), definedTags = map(string) })
  default = { "definedTags" = {}, "freeformTags" = { "CreatedBy" = "Terraform" } }
}

variable "log_group_name" {
  type    = string
  default = "dev-loggroup"
}

variable "log_group_description" {
  type     = string
  nullable = true
  default  = null
}
