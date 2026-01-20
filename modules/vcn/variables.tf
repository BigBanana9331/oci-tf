variable "tenancy_ocid" {}

variable "compartment_id" {}

variable "vcn_cidr_blocks" {
  type = list(string)
}

variable "vcn_name" {
  type    = string
  default = "acme-dev-vcn"
}

variable "internet_gateway_enabled" {
  type    = bool
  default = true
}

variable "internet_gateway_name" {
  type    = string
  default = "internet-gateway-0"
}

variable "nat_gateway_name" {
  type    = string
  default = "nat-gateway-0"
}

variable "service_gateway_name" {
  type    = string
  default = "service-gateway-0"
}

variable "service_name" {
  type    = string
  default = "All SIN Services In Oracle Services Network"
}

variable "dhcp_options_name" {
  type    = string
  default = "dhcp-options-0"
}

variable "dhcp_options_type" {
  type    = string
  default = "DomainNameServer"
}

variable "dhcp_options_server_type" {
  type    = string
  default = "VcnLocalPlusInternet"
}

variable "security_lists" {
  type = map(object({
    egress_security_rules = optional(set(object({
      protocol         = string
      destination      = string
      destination_type = optional(string)
      description      = optional(string)
      stateless        = optional(bool, false)

      icmp_options = optional(object({
        type = number
        code = optional(number)
      }))

      tcp_options = optional(object({
        max = number
        min = number
      }))

      udp_options = optional(object({
        max = number
        min = number
      }))
    })))

    ingress_security_rules = optional(set(object({
      protocol    = string
      source      = string
      source_type = optional(string)
      description = optional(string)
      stateless   = optional(bool, false)

      icmp_options = optional(object({
        type = number
        code = optional(number)
      }))

      tcp_options = optional(object({
        max = number
        min = number
      }))

      udp_options = optional(object({
        max = number
        min = number
      }))
    })))
  }))
  default = {
    "default_security_list" = {
      egress_security_rules = [
        {
          protocol         = "6"
          destination      = "0.0.0.0/0"
          destination_type = "CIDR_BLOCK"
          description      = "TCP traffic for ports: 22 SSH Remote Login Protocol"
          tcp_options = {
            max = 22
            min = 22
          }
        },
        {
          protocol         = "1"
          destination      = "0.0.0.0/0"
          destination_type = "CIDR_BLOCK"
          description      = "ICMP traffic for: 3, 4 Destination Unreachable: Fragmentation Needed and Don't Fragment was Set"
          icmp_options = {
            type = 3
            code = 4
          }
        },
        {
          protocol         = "1"
          destination      = "10.0.0.0/16"
          destination_type = "CIDR_BLOCK"
          description      = "ICMP traffic for: 3 Destination Unreachable"
          icmp_options = {
            type = 3
          }
        },
      ]

      ingress_security_rules = [
        {
          protocol    = "all"
          source      = "0.0.0.0/0"
          source_type = "CIDR_BLOCK"
          description = "All traffic for all ports"
        }
      ]
    }
  }
}

variable "route_tables" {
  type = map(set(object({
    network_entity_name = string
    description         = optional(string)
    destination         = optional(string)
    destination_type    = optional(string)
  })))
  default = {
    "routetable-private" = [
      {
        network_entity_name = "natgw"
        destination         = "0.0.0.0/0"
        destination_type    = "CIDR_BLOCK"
        description         = "Rule for traffic to internet"
      },
      {
        network_entity_name = "svcgw"
        destination         = "all-sin-services-in-oracle-services-network"
        destination_type    = "SERVICE_CIDR_BLOCK"
        description         = "Rule for traffic to OCI services"
      }
    ],
    "routetable-public" = [
      {
        network_entity_name = "intgw"
        destination         = "0.0.0.0/0"
        destination_type    = "CIDR_BLOCK"
        description         = "Rule for traffic to internet"
      }
    ]
  }
}

variable "subnets" {
  type = map(object({
    cidr_block                = string
    dhcp_options_id           = optional(string)
    prohibit_internet_ingress = optional(bool, false)
    route_table_name            = optional(string)
    security_list_names         = optional(list(string))
  }))
  default = {
    "KubernetesAPIendpoint" = {
      cidr_block                = "10.0.0.0/30"
      prohibit_internet_ingress = true
      route_table_name           = "routetable-private"
      security_list_names         = ["default_security_list"]
    },
    "workernodes" = {
      cidr_block                = "10.0.1.0/24"
      prohibit_internet_ingress = true
      route_table_name            = "routetable-private"
      security_list_names         = ["default_security_list"]
    },
    "loadbalancers" = {
      cidr_block        = "10.0.2.0/24"
      route_table_name    = "routetable-public"
      security_list_names = ["default_security_list"]
    },
    "bastion" = {
      cidr_block                = "10.0.3.0/24"
      prohibit_internet_ingress = true
      route_table_name            = "routetable-private"
      security_list_names         = ["default_security_list"]
    }
  }
}

variable "nsgs" {
  type = map(list(object({
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
  # default = null
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
        protocol    = "6"
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
        icmp_options = {
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
