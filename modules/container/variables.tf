terraform {
  required_version = ">= 1.5.7"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.30"
    }
  }
}

variable "tenancy_ocid" {
  type = string
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

variable "policy" {
  type = object({
    description = optional(string, "policy created by terraform")
    name        = optional(string, "oke-policy")
  })
  default = {
    description = "policy created by terraform"
    name        = "oke-policy"
  }
}

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

variable "vcn_name" {
  type    = string
  default = "vcn-0"
}

variable "vault_name" {
  type     = string
  nullable = true
  default  = null
}

variable "key_name" {
  type     = string
  default  = null
  nullable = true
}

variable "ssh_secret_name" {
  type     = string
  nullable = true
  default  = null
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

variable "node_pool_option_id" {
  type    = string
  default = "all"
}

variable "node_pool_os_arch" {
  type    = string
  default = "X86_64"
}

variable "node_pool_os_type" {
  type    = string
  default = "OL8"
}

variable "cluster_subnet_name" {
  type    = string
  default = "subnet-oke-apiendpoint"
}

variable "endpoint_nsg_names" {
  type     = set(string)
  nullable = true
  default  = ["nsg-oke-apiendpoint"]
}

variable "cni_type" {
  type    = string
  default = "FLANNEL_OVERLAY"
}

variable "is_public_endpoint_enabled" {
  type    = bool
  default = false
}

variable "is_pod_security_policy_enabled" {
  type    = bool
  default = false
}

variable "loadbalancer_subnet_name" {
  type    = string
  default = "subnet-oke-serviceloadbalancer"
}

variable "worker_subnet_name" {
  type    = string
  default = "subnet-oke-workernode"
}

variable "services_cidr" {
  type    = string
  default = "10.96.0.0/16"
}

variable "pods_cidr" {
  type    = string
  default = "10.244.0.0/16"
}

variable "node_pools" {
  type = map(object({
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

  default = {
    "pool-0" = {
      node_shape                          = "VM.Standard.E5.Flex"
      node_shape_ocpus                    = 1
      node_shape_memory_in_gbs            = 8
      node_pool_size                      = 1
      cni_type                            = "FLANNEL_OVERLAY"
      node_nsg_names                      = ["nsg-oke-workernode"]
      is_pv_encryption_in_transit_enabled = true

      node_metadata = {
        meta = "meta1"
      }

      initial_node_labels = {
        label = "label1"
      }
    }
  }
}




