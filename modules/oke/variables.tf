variable "tenancy_ocid" {}

variable "compartment_id" {}

variable "vcn_name" {
  type    = string
  default = "acme-dev-vcn"
}

variable "nsgs" {
  type = map(set(object({
    direction        = string
    protocol         = string
    source           = optional(string)
    destination      = optional(string)
    destination_type = optional(string)
    source_type      = optional(string)
    stateless        = optional(bool)
    description      = optional(string)

    icmp_options = optional(object({
      type = optional(number)
      code = optional(number)
    }))

    tcp_options = optional(object({
      destination_port_range = optional(object({
        max = optional(number)
        min = optional(number)
      }))
      source_port_range = optional(object({
        max = optional(number)
        min = optional(number)
      }))
    }))

    udp_options = optional(object({
      destination_port_range = optional(object({
        max = optional(number)
        min = optional(number)
      }))
      source_port_range = optional(object({
        max = optional(number)
        min = optional(number)
      }))
    }))
  })))

  nullable = true
  default = {
    "nsg-bastion" = [
      {
        direction        = "EGRESS"
        protocol         = "6"
        destination_type = "CIDR_BLOCK"
        destination      = "10.0.0.0/30"
        description      = "Allow bastion to Kubernetes API endpoint communication."
        tcp_options = {
          destination_port_range = {
            min = 6443
            max = 6443
          }
        }
      },
      {
        direction        = "EGRESS"
        protocol         = "6"
        destination_type = "CIDR_BLOCK"
        destination      = "10.0.1.0/24"
        description      = "Allow bastion to worker nodes communication."
        tcp_options = {
          destination_port_range = {
            min = 22
            max = 22
          }
        }
      }
    ]
    "nsg-loadbalancers" = [
      {
        direction        = "EGRESS"
        protocol         = "6"
        destination_type = "CIDR_BLOCK"
        destination      = "10.0.1.0/24"
        description      = "Allow traffic to worker nodes."
        tcp_options = {
          destination_port_range = {
            min = 30000
            max = 32767
          }
        }
      },
      {
        direction        = "EGRESS"
        protocol         = "6"
        destination_type = "CIDR_BLOCK"
        destination      = "10.0.1.0/24"
        description      = "Allow OCI load balancer or network load balancer to communicate with kube-proxy on worker nodes."
        tcp_options = {
          destination_port_range = {
            min = 12256
            max = 12256
          }
        }
      }
    ]
    "nsg-workernodes" = [
      {
        direction        = "EGRESS"
        protocol         = "all"
        destination_type = "CIDR_BLOCK"
        destination      = "10.0.1.0/24"
        description      = "Allows communication from (or to) worker nodes."
      },
      {
        direction        = "EGRESS"
        protocol         = "1"
        destination_type = "CIDR_BLOCK"
        destination      = "0.0.0.0/0"
        description      = "Path Discovery."
        icmp_options = {
          type = 3
          code = 4
        }
      },
      {
        direction        = "EGRESS"
        protocol         = "6"
        destination_type = "SERVICE_CIDR_BLOCK"
        destination      = "all-sin-services-in-oracle-services-network"
        description      = "Allow nodes to communicate with OKE."
      },
      {
        direction        = "EGRESS"
        protocol         = "6"
        destination_type = "CIDR_BLOCK"
        destination      = "10.0.0.0/30"
        description      = "Kubernetes worker to Kubernetes API endpoint communication."
        tcp_options = {
          destination_port_range = {
            min = 6443
            max = 6443
          }
        }
      },
      {
        direction        = "EGRESS"
        protocol         = "6"
        destination_type = "CIDR_BLOCK"
        destination      = "10.0.0.0/30"
        description      = "Kubernetes worker to Kubernetes API endpoint communication."
        tcp_options = {
          destination_port_range = {
            min = 12250
            max = 12250
          }
        }
      },
      {
        direction        = "EGRESS"
        protocol         = "6"
        destination_type = "CIDR_BLOCK"
        destination      = "10.0.0.0/30"
        description      = "To allow com with Kubelet API"
        tcp_options = {
          destination_port_range = {
            min = 10250
            max = 10250
          }
        }
      },
      {
        direction   = "INGRESS"
        protocol    = "all"
        source_type = "CIDR_BLOCK"
        source      = "10.0.1.0/24"
        description = "Allows communication from (or to) worker nodes."
      },
      {
        direction   = "INGRESS"
        protocol    = "6"
        source_type = "CIDR_BLOCK"
        source      = "10.0.0.0/30"
        description = "Allow Kubernetes API endpoint to communicate with worker nodes."
        tcp_options = {
          destination_port_range = {
            min = 1
            max = 65535
          }
        }
      },
      {
        direction   = "INGRESS"
        protocol    = "1"
        source_type = "CIDR_BLOCK"
        source      = "0.0.0.0/0"
        description = "Path Discovery."
        icmp_options = {
          type = 3
          code = 4
        }
      },
      {
        direction   = "INGRESS"
        protocol    = "6"
        source_type = "CIDR_BLOCK"
        source      = "10.0.2.0/24"
        description = "Allow OCI load balancer or network load balancer to communicate with kube-proxy on worker nodes."
        tcp_options = {
          destination_port_range = {
            min = 10256
            max = 10256
          }
        }
      },
      {
        direction   = "INGRESS"
        protocol    = "6"
        source_type = "CIDR_BLOCK"
        source      = "10.0.3.0/24"
        description = "Allow bastion to worker nodes communication."
        tcp_options = {
          destination_port_range = {
            min = 22
            max = 22
          }
        }
      },
      {
        direction   = "INGRESS"
        protocol    = "all"
        source_type = "CIDR_BLOCK"
        source      = "10.0.0.0/30"
        description = "Allow com to kubelet API"
        tcp_options = {
          destination_port_range = {
            min = 10250
            max = 10250
          }
        }
      }
    ]
    "nsg-KubernetesAPIendpoint" = [
      {
        direction        = "EGRESS"
        protocol         = "6"
        destination_type = "SERVICE_CIDR_BLOCK"
        destination      = "all-sin-services-in-oracle-services-network"
        description      = "Allow Kubernetes control plane to communicate with OKE."
        tcp_options = {
          destination_port_range = {
            min = 443
            max = 443
          }
        }
      },
      {
        direction        = "EGRESS"
        protocol         = "6"
        destination_type = "CIDR_BLOCK"
        destination      = "10.0.1.0/24"
        description      = "All traffic to worker nodes (when using flannel for pod networking)."
      },
      {
        direction        = "EGRESS"
        protocol         = "1"
        destination_type = "CIDR_BLOCK"
        destination      = "10.0.1.0/24"
        description      = "Path Discovery."
        tcp_options = {
          type = 3
          code = 4
        }
      },
      {
        direction        = "EGRESS"
        protocol         = "6"
        destination_type = "CIDR_BLOCK"
        destination      = "10.0.1.0/24"
        description      = "To allow communication with Worker node kubelet"
        tcp_options = {
          destination_port_range = {
            min = 10250
            max = 10250
          }
        }
      },
      {
        direction        = "EGRESS"
        protocol         = "6"
        destination_type = "CIDR_BLOCK"
        destination      = "10.0.3.0/24"
        description      = "Allow bastion host communication with API Server Endpoint"
        tcp_options = {
          destination_port_range = {
            min = 6443
            max = 6443
          }
        }
      },
      {
        direction   = "INGRESS"
        protocol    = "6"
        source_type = "CIDR_BLOCK"
        source      = "10.0.1.0/24"
        description = "Kubernetes worker to Kubernetes API endpoint communication."
        tcp_options = {
          destination_port_range = {
            min = 6443
            max = 6443
          }
        }
      },
      {
        direction   = "INGRESS"
        protocol    = "6"
        source_type = "CIDR_BLOCK"
        source      = "10.0.1.0/24"
        description = "Kubernetes worker to Kubernetes API endpoint communication."
        tcp_options = {
          destination_port_range = {
            min = 12250
            max = 12250
          }
        }
      },
      {
        direction   = "INGRESS"
        protocol    = "1"
        source_type = "CIDR_BLOCK"
        source      = "10.0.1.0/24"
        description = "Path Discovery."
        icmp_options = {
          type = 3
          code = 4
        }
      },
      {
        direction   = "INGRESS"
        protocol    = "6"
        source_type = "CIDR_BLOCK"
        source      = "10.0.3.0/24"
        description = "Allow bastion to Kubernetes API endpoint communication."
        tcp_options = {
          destination_port_range = {
            min = 6443
            max = 6443
          }
        }
      }
    ]
  }
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

variable "cluster_subnet_name" {
  type    = string
  default = "controlplane"
}

variable "endpoint_nsg_ids" {
  type     = set(string)
  nullable = true
  default  = null
}

variable "cni_types" {
  type = set(string)
  default = [
    "FLANNEL",
    "OCI_VCN_IP_NATIVE"
  ]
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
}

variable "addons" {
  type = map(object({
    remove_addon_resources_on_delete = optional(bool, true)
    override_existing                = optional(bool, false)
    version                          = string
    configurations                   = set(map(string))
  }))
}

