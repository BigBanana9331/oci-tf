variable "config_file_profile" {
  type = string
}

variable "tenancy_ocid" {
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
  default = "helloapp"
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


variable "oke" {
  type = object({
    vcn_name                 = string
    cluster_name             = string
    cluster_type             = string
    kubernetes_version       = string
    cluster_subnet_name      = string
    endpoint_nsg_names       = set(string)
    cni_type                 = string
    loadbalancer_subnet_name = string
    worker_subnet_name       = string
    services_cidr            = string
    pods_cidr                = string

    log_group = object({
      name = string
    })

    instance_dynamic_group = object({
      name = string
    })

    policy = object({
      name = string
    })
    unified_agent_configuration = object({
      name               = string
      is_enabled         = bool
      configuration_type = string
      log_object_name    = string
      source = object({
        name        = string
        source_type = string
        paths       = list(string)
        parser_type = string
      })
    })

    logs = map(object({
      is_enabled         = optional(bool, true)
      retention_duration = optional(number, 30)
      type               = optional(string, "CUSTOM")
      source_type        = optional(string)
      service            = optional(string)
      resource           = optional(string)
      category           = optional(string)
      parameters         = optional(map(string))
    }))

    node_pools = map(object({
      node_shape                           = string
      node_pool_size                       = number
      cni_type                             = string
      is_pv_encryption_in_transit_enabled  = optional(bool, null)
      key_name                             = optional(string, null)
      node_metadata                        = optional(map(string))
      initial_node_labels                  = optional(map(string))
      node_shape_ocpus                     = optional(number, null)
      node_shape_memory_in_gbs             = optional(number, null)
      eviction_grace_duration              = optional(string, null)
      is_force_action_after_grace_duration = optional(bool, null)
      is_force_delete_after_grace_duration = optional(bool, null)
      node_nsg_names                       = optional(set(string), [])
      cycle_modes                          = optional(set(string), ["INSTANCE_REPLACE"])
      is_node_cycling_enabled              = optional(bool, false)
      maximum_surge                        = optional(number, 1)
      maximum_unavailable                  = optional(number, 1)
      image_id                             = optional(string, "ocid1.image.oc1.ap-singapore-1.aaaaaaaa2a3rqme4763azdnhuj47wft43q5o236g7jbglkfhogprk44o2bta")
      source_type                          = optional(string, "IMAGE")
    }))

    autoscaler = object({
      is_enabled = bool
      min_node   = number
      max_node   = number
    })
  })
}