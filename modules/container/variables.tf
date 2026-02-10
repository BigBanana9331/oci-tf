terraform {
  required_version = "~> 1.14"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.0"
    }
  }
}

variable "compartment_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "app_name" {
  type     = string
  nullable = true
  default  = null
}

variable "tags" {
  type    = object({ freeformTags = map(string), definedTags = map(string) })
  default = { "definedTags" = {}, "freeformTags" = { "CreatedBy" = "Terraform" } }
}

variable "cluster_name" {
  type    = string
  default = "oke-0"
}

variable "cluster_type" {
  type    = string
  default = "ENHANCED_CLUSTER"
}

variable "kubernetes_version" {
  type    = string
  default = "v1.34.1"
}

variable "vcn_id" {
  type = string
}

variable "cluster_subnet_id" {
  type = string
}

variable "endpoint_nsg_ids" {
  type     = set(string)
  nullable = true
}

variable "backend_nsg_ids" {
  type     = list(string)
  nullable = true
  default  = null
}

variable "cni_type" {
  type    = string
  default = "FLANNEL_OVERLAY"
}

variable "is_public_endpoint_enabled" {
  type    = bool
  default = false
}

variable "loadbalancer_subnet_ids" {
  type = list(string)
}

variable "worker_subnet_id" {
  type = string
}

variable "services_cidr" {
  type    = string
  default = "10.96.0.0/16"
}

variable "pods_cidr" {
  type    = string
  default = "10.244.0.0/16"
}

variable "is_pod_security_policy_enabled" {
  type    = bool
  default = false
}

variable "kms_key_id" {
  nullable    = true
  default     = null
  type        = string
  description = "Encryption Key OCID"
}

variable "image_policy_config" {
  nullable = true
  default  = null
  type = object({
    is_policy_enabled = bool
    key_ids           = list(string)
  })
}

variable "log_group" {
  type = object({
    name        = string
    description = optional(string)
  })
  default = {
    description = "OKE loggroup"
    name        = "oke-loggroup"
  }
}

variable "instance_dynamic_group" {
  type = object({
    description = optional(string)
    name        = optional(string, "nodes-dg")
  })
  default = {
    description = "Nodepool dyanmic group"
    name        = "nodes-dg"
  }
}

# variable "policy" {
#   type = object({
#     description = optional(string, "policy created by terraform")
#     name        = optional(string, "oke-policy")
#   })
#   default = {
#     description = "policy created by terraform"
#     name        = "oke-policy"
#   }
# }

variable "unified_agent_configuration" {
  type = object({
    description        = optional(string, "Custom log confguration")
    name               = optional(string, "nodes-uac")
    is_enabled         = optional(bool, true)
    configuration_type = optional(string, "LOGGING")
    log_object_name    = optional(string, "customlog-oke")
    source = object({
      name        = optional(string, "worker-logtail")
      source_type = optional(string, "LOG_TAIL")
      paths       = optional(list(string), ["/var/log/containers/*", "/var/log/pods/*"])
      parser_type = optional(string, "NONE")
    })
  })
  default = {
    description        = "Custom log confguration"
    name               = "nodes-uac"
    is_enabled         = true
    configuration_type = "LOGGING"
    log_object_name    = "customlog-oke"
    source = {
      name        = "worker-logtail"
      source_type = "LOG_TAIL"
      paths       = ["/var/log/containers/*", "/var/log/pods/*"]
      parser_type = "NONE"
    }
  }
}

variable "logs" {
  type = map(object({
    is_enabled         = optional(bool, true)
    retention_duration = optional(number, 30)
    type               = optional(string, "CUSTOM")
    source_type        = optional(string)
    service            = optional(string)
    resource           = optional(string)
    category           = optional(string)
    parameters         = optional(map(string))
  }))
  default = {
    "servicelog-oke" = {
      type        = "SERVICE"
      source_type = "OCISERVICE"
      service     = "oke-k8s-cp-prod"
      category    = "all-service-logs"
    }
    "customlog-oke" = {
      type = "CUSTOM"
    }
  }
}

variable "policies" {
  type = map(string)
  default = {
    # "netpol"     = "Networking policy for OKE"
    # "secpol"     = "Security policy for OKE"
    # "computepol" = "Compute policy for OKE"
    logpol = "Policy for instances node group logging"
  }
}

variable "node_pools" {
  type = map(object({
    node_shape                           = string
    node_pool_size                       = number
    cni_type                             = string
    is_pv_encryption_in_transit_enabled  = optional(bool)
    kms_key_id                           = optional(string)
    node_metadata                        = optional(map(string))
    initial_node_labels                  = optional(map(string))
    node_shape_ocpus                     = optional(number)
    node_shape_memory_in_gbs             = optional(number)
    eviction_grace_duration              = optional(string)
    is_force_action_after_grace_duration = optional(bool)
    is_force_delete_after_grace_duration = optional(bool)
    node_nsg_ids                         = optional(set(string), [])
    cycle_modes                          = optional(set(string), ["INSTANCE_REPLACE"])
    is_node_cycling_enabled              = optional(bool, false)
    maximum_surge                        = optional(number, 1)
    maximum_unavailable                  = optional(number, 1)
    image_id                             = optional(string)
    source_type                          = optional(string, "IMAGE")
    boot_volume_size_in_gbs              = optional(number, 50)
    availability_domain                  = optional(string)
  }))
}

variable "autoscaler" {
  type = object({
    is_enabled = optional(bool, true)
    min_node   = optional(number, 1)
    max_node   = optional(number, 2)
  })
  default = {
    is_enabled = true
    min_node   = 1
    max_node   = 2
  }
}




