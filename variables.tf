variable "config_file_profile" {
  type = string
}

variable "tenancy_ocid" {
  type = string
}

variable "ad_number" {
  type    = number
  default = 1
}

variable "compartment_ocid" {
  type = string
}

variable "vault_compartment_id" {
  type = string
}

variable "vault_name" {
  type    = string
  default = "dev-vault"
}

variable "admin_password_secret_name" {
  type    = string
  default = "dev-mysql-admin-password"
}

variable "vcn_compartment_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "app_name" {
  type    = string
  default = "helloapp"
}

variable "node_pool_option_id" {
  type    = string
  default = "all"
}

variable "node_pool_os_type" {
  type    = string
  default = "OL8"
}

variable "node_pool_os_arch" {
  type    = string
  default = "X86_64"
}

variable "node_pool_k8s_version" {
  type    = string
  default = "v1.34.1"
}

variable "vcn_name" {
  type        = string
  description = "application vcn"
}

variable "bastion" {
  nullable = true
  default  = null
  type = object({
    subnet_name                = string
    bastion_name               = string
    max_session_ttl_in_seconds = number
  })
}

variable "apigw" {
  nullable = true
  default  = null
  type = object({
    subnet_name  = string
    gateway_name = string
    nsg_names    = list(string)
  })
}


variable "oke" {
  nullable = true
  default  = null
  type = object({
    cluster_name            = string
    cluster_type            = string
    kubernetes_version      = string
    cluster_subnet_name     = string
    endpoint_nsg_names      = set(string)
    cni_type                = string
    loadbalancer_subnet_ids = list(string)
    worker_subnet_name      = string
    services_cidr           = string
    pods_cidr               = string
    kms_key_name              = string
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

variable "mysql" {
  nullable = true
  default  = null
  type = object({
    subnet_name             = string
    nsg_names               = set(string)
    shape_name              = string
    display_name            = string
    data_storage_size_in_gb = number
    is_highly_available     = bool
    key_name                = string
  })
}
