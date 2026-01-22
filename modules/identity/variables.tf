variable "compartment_id" {}

variable "namespace" {
  type = object({
    name        = string
    description = optional(string)
    is_retired  = optional(bool, false)
    tags = map(object({
      description      = optional(string)
      is_cost_tracking = optional(bool, false)
      is_retired       = optional(bool, false)
    }))
  })

  default = {
    name        = "AutoTagging"
    description = "Automation tag namespace when created resource"
    tags = {
      "AppName" = {
        description = "Managed Application Name"
      }
      "CreatedBy" = {
        description = "Which created reources"
      }
    }
  }
}