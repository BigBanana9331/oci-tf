variable "tenancy_ocid" {
  type = string
}

variable "compartment_ocid" {
  type = string
}

variable "region" {
  type = string
}

# variable "api_gateway" {
#   type = object({
#     compartment_id = string
#     vcn_name       = string
#     subnet_name    = string
#     gateway_name   = string
#     endpoint_type  = string
#     ip_mode        = string
#     nsg_names      = list(string)
#     tags           = object({ freeformTags = map(string), definedTags = map(string) })
#   })
# }