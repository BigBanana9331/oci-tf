variable "tenancy_ocid" {
  type = string
}

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
    "dev-servicelog-oke" = {
      type        = "SERVICE"
      source_type = "OCISERVICE"
      service     = "oke-k8s-cp-prod"
      # resource    = "dev-oke"
      category = "all-service-logs"
    }
    "dev-customlog-oke" = {
      type = "CUSTOM"
    }
  }
}

variable "vcn_name" {
  type    = string
  default = "dev-vcn"
}

variable "vault_name" {
  type    = string
  default = "dev-vault"
}

variable "key_name" {
  type    = string
  default = "master-key"
}

variable "cluster_name" {
  type    = string
  default = "dev-oke"
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
  default = "dev-subnet-oke-apiendpoint"
}

variable "endpoint_nsg_names" {
  type     = set(string)
  nullable = true
  default  = ["dev-nsg-oke-apiendpoint "]
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
  default = "dev-subnet-oke-serviceloadbalancer"
}

variable "worker_subnet_name" {
  type    = string
  default = "dev-subnet-oke-workernode"
}

variable "services_cidr" {
  type    = string
  default = "10.96.0.0/16"
}

variable "pods_cidr" {
  type    = string
  default = "10.244.0.0/16"
}

variable "ca_certificate" {
  type     = string
  nullable = true
  default  = null
}

variable "client_id" {
  type     = string
  nullable = true
  default  = null
}

variable "configuration_file" {
  type     = string
  nullable = true
  default  = null
}

variable "groups_prefix" {
  type     = string
  nullable = true
  default  = null
}

variable "is_open_id_connect_auth_enabled" {
  type     = bool
  nullable = true
  default  = null
}

variable "issuer_url" {
  type     = string
  nullable = true
  default  = null
}

variable "signing_algorithms" {
  type     = list(string)
  nullable = true
  default  = null
}

variable "username_claim" {
  type     = string
  nullable = true
  default  = null
}

variable "username_prefix" {
  type     = string
  nullable = true
  default  = null
}

variable "required_claims" {
  type    = map(string)
  default = {}
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
      node_shape               = "VM.Standard.E5.Flex"
      node_shape_ocpus         = 1
      node_shape_memory_in_gbs = 8
      node_pool_size           = 1
      cni_type                 = "FLANNEL_OVERLAY"
      node_nsg_names           = ["dev-nsg-oke-workernode"]
    }
  }
}




