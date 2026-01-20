variable "tenancy_ocid" {}

variable "compartment_id" {}

variable "vcn_name" {
  type    = string
  default = "acme-dev-vcn"
}

# variable "vcn_id" {
#   type = string
#   nullable = true

# }

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

variable "cluster_subnet_name" {
  type    = string
  default = "KubernetesAPIendpoint"
}

variable "endpoint_nsg_ids" {
  type     = set(string)
  nullable = true
  default  = ["nsg-KubernetesAPIendpoint"]
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
  default = "loadbalancers"
}

variable "worker_subnet_name" {
  type    = string
  default = "workernodes"
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
    node_shape_ocpus                     = optional(number, null)
    node_shape_memory_in_gbs             = optional(number, null)
    eviction_grace_duration              = optional(string, null)
    is_force_action_after_grace_duration = optional(bool, null)
    is_force_delete_after_grace_duration = optional(bool, null)
    node_nsg_ids                         = optional(set(string), [])
    cycle_modes                          = optional(set(string), [])
    is_node_cycling_enabled              = optional(bool, null)
    maximum_surge                        = optional(number, null)
    maximum_unavailable                  = optional(number, null)
  }))
  default = {
    "pool-0" = {
      node_shape     = "VM.Standard.E.Flex"
      node_pool_size = 1
      cni_type       = "FLANNEL_OVERLAY"
    }
  }
}

variable "addons" {
  type = map(object({
    remove_addon_resources_on_delete = optional(bool, true)
    override_existing                = optional(bool, false)
    version                          = string
    configurations                   = set(map(string))
  }))
  nullable = true
  default  = null
}

