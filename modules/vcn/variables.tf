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
    "seclist-KubernetesAPIendpoint" = {
      ingress_security_rules = [
        {
          protocol    = "6"
          source      = "10.0.1.0/24"
          description = "Kubernetes worker to Kubernetes API endpoint communication."
          source_type = "CIDR_BLOCK"
          tcp_options = {
            min = 6443
            max = 6443
          }
        },
        {
          protocol    = "6"
          source      = "10.0.1.0/24"
          description = "Kubernetes worker to control plane communication."
          source_type = "CIDR_BLOCK"
          tcp_options = {
            min = 12250
            max = 12250
          }
        },
        {
          protocol    = "1"
          source      = "10.0.1.0/24"
          description = "	Path Discovery."
          source_type = "CIDR_BLOCK"
          icmp_options = {
            type = 3
            code = 4
          }
        },
        {
          protocol    = "6"
          source      = "10.0.3.0/24"
          description = "Bastion subnet CIDR when access is made through OCI Bastion"
          source_type = "CIDR_BLOCK"
          tcp_options = {
            min = 6443
            max = 6443
          }
        }
      ]
      egress_security_rules = [
        {
          protocol         = "6"
          destination      = "all-sin-services-in-oracle-services-network"
          description      = "Allow Kubernetes control plane to communicate with OKE."
          destination_type = "SERVICE_CIDR_BLOCK"
          stateless        = false
        },
        {
          protocol         = "1"
          destination      = "all-sin-services-in-oracle-services-network"
          description      = "Path Discovery."
          destination_type = "SERVICE_CIDR_BLOCK"
          stateless        = false
          icmp_options = {
            type = 3
            code = 4
          }
        },
        {
          protocol         = "6"
          destination      = "10.0.1.0/24"
          description      = "Allow Kubernetes control plane to communicate with worker nodes."
          destination_type = "CIDR_BLOCK"
          stateless        = false
        },
        {
          protocol         = "1"
          destination      = "10.0.1.0/24"
          description      = "Path Discovery."
          destination_type = "CIDR_BLOCK"
          stateless        = false
          icmp_options = {
            type = 3
            code = 4
          }
        }
      ]
    }
    seclist-workernodes = {
      egress_security_rules = [
        {
          protocol         = "all"
          destination      = "10.0.1.0/24"
          description      = "Allow pods on one worker node to communicate with pods on other worker nodes."
          destination_type = "CIDR_BLOCK"
          stateless        = false
        },
        {
          protocol         = "6"
          destination      = "all-sin-services-in-oracle-services-network"
          description      = "Allow load balancer to communicate with kube-proxy on worker nodes."
          destination_type = "SERVICE_CIDR_BLOCK"
          stateless        = false
        },
        {
          protocol         = "6"
          destination      = "10.0.0.0/30"
          description      = "Kubernetes worker to Kubernetes API endpoint communication."
          destination_type = "CIDR_BLOCK"
          stateless        = false
          tcp_options = {
            min = 6443
            max = 6443
          }
        },
        {
          protocol         = "6"
          destination      = "10.0.0.0/30"
          description      = "Kubernetes worker to control plane communication."
          destination_type = "CIDR_BLOCK"
          stateless        = false
          tcp_options = {
            min = 12250
            max = 12250
          }
        },
        {
          protocol         = "6"
          destination      = "0.0.0.0/0"
          description      = "Allow worker nodes to communicate with internet."
          destination_type = "CIDR_BLOCK"
          stateless        = false
        }
      ]
      ingress_security_rules = [
        {
          protocol    = "all"
          source      = "10.0.1.0/24 "
          description = "Allow pods on one worker node to communicate with pods on other worker nodes."
          source_type = "CIDR_BLOCK"
        },
        {
          protocol    = "6"
          source      = "10.0.0.0/30"
          description = "Allow Kubernetes control plane to communicate with worker nodes."
          source_type = "CIDR_BLOCK"
        },
        {
          protocol    = "1"
          source      = "0.0.0.0/0"
          description = "Path Discovery."
          source_type = "CIDR_BLOCK"
          icmp_options = {
            type = 3
            code = 4
          }
        },
        {
          protocol    = "6"
          source      = "10.0.3.0/24"
          description = "Allow inbound SSH traffic to managed nodes."
          source_type = "CIDR_BLOCK"
          tcp_options = {
            min = 22
            max = 22
          }
        },
        {
          protocol    = "all"
          source      = "10.0.2.0/24"
          description = "Load balancer to worker nodes node ports."
          source_type = "CIDR_BLOCK"
          tcp_options = {
            min = 30000
            max = 32767
          }
        },
        {
          protocol    = "all"
          source      = "10.0.2.0/24"
          description = "Allow load balancer to communicate with kube-proxy on worker nodes."
          source_type = "CIDR_BLOCK"
          tcp_options = {
            min = 10256
            max = 10256
          }
        }
      ]
    }
    seclist-loadbalancers = {
      egress_security_rules = [
        {
          protocol         = "all"
          destination      = "10.0.1.0/24"
          description      = "Load balancer to worker nodes node ports."
          destination_type = "CIDR_BLOCK"
          tcp_options = {
            min = 30000
            max = 32767
          }
        },
        {
          protocol         = "all"
          destination      = "10.0.1.0/24"
          description      = "Allow load balancer to communicate with kube-proxy on worker nodes."
          destination_type = "CIDR_BLOCK"
          tcp_options = {
            min = 10256
            max = 10256
          }
        }
      ]
      ingress_security_rules = [
        {
          protocol    = "6"
          source      = "0.0.0.0/0"
          description = "Allow HTTP traffic from internet."
          source_type = "CIDR_BLOCK"
          tcp_options = {
            min = 443
            max = 443
          }
        }
      ]
    }
    seclist-Bastion = {
      egress_security_rules = [
        {
          protocol         = "6"
          destination      = "10.0.0.0/30"
          description      = "Load balancer to worker nodes node ports."
          destination_type = "CIDR_BLOCK"
          tcp_options = {
            min = 30000
            max = 32767
          }
        },
        {
          protocol         = "6"
          destination      = "10.0.1.0/24"
          description      = "Allow SSH traffic to worker nodes."
          destination_type = "CIDR_BLOCK"
          tcp_options = {
            min = 22
            max = 22
          }
        }
      ]
      ingress_security_rules = []
    }
  }
}

variable "route_tables" {
  type = map(set(object({
    network_entity_id = string
    description       = optional(string)
    destination       = optional(string)
    destination_type  = optional(string)
  })))
  default = {
    "routetable-KubernetesAPIendpoint" = [
      {
        network_entity_id = "natgw"
        destination       = "0.0.0.0/0"
        destination_type  = "CIDR_BLOCK"
        description       = "Rule for traffic to internet"
      },
      {
        network_entity_id = "svcgw"
        destination       = "all-sin-services-in-oracle-services-network"
        destination_type  = "SERVICE_CIDR_BLOCK"
        description       = "Rule for traffic to OCI services"
      }
    ],
    "routetable-workernodes" = [
      {
        network_entity_id = "natgw"
        destination       = "0.0.0.0/0"
        destination_type  = "CIDR_BLOCK"
        description       = "Rule for traffic to internet"
      },
      {
        network_entity_id = "svcgw"
        destination       = "all-sin-services-in-oracle-services-network"
        destination_type  = "SERVICE_CIDR_BLOCK"
        description       = "Rule for traffic to OCI services"
      }
    ],
    "routetable-loadbalancers" = [
      {
        network_entity_id = "intgw"
        destination       = "0.0.0.0/0"
        destination_type  = "CIDR_BLOCK"
        description       = "Rule for traffic to internet"
      }
    ]
  }
}

variable "subnets" {
  type = map(object({
    cidr_block                = string
    dhcp_options_id           = optional(string)
    prohibit_internet_ingress = optional(bool, false)
    route_table_id            = optional(string)
    security_list_ids         = optional(list(string))
  }))
  default = {
    "KubernetesAPIendpoint" = {
      cidr_block                = "10.0.0.0/30"
      prohibit_internet_ingress = true
      route_table_id            = "routetable-KubernetesAPIendpoint"
      security_list_ids         = ["seclist-KubernetesAPIendpoint"]
    },
    "workernodes" = {
      cidr_block                = "10.0.1.0/24"
      prohibit_internet_ingress = true
      route_table_id            = "routetable-KubernetesAPIendpoint"
      security_list_ids         = ["seclist-KubernetesAPIendpoint"]
    },
    "loadbalancers" = {
      cidr_block        = "10.0.2.0/24"
      route_table_id    = "routetable-KubernetesAPIendpoint"
      security_list_ids = ["seclist-KubernetesAPIendpoint"]
    },
    "bastion" = {
      cidr_block                = "10.0.3.0/24"
      prohibit_internet_ingress = true
      route_table_id            = "routetable-KubernetesAPIendpoint"
      security_list_ids         = ["seclist-KubernetesAPIendpoint"]
    }
  }
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