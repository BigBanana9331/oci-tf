variable "environment" {
  type        = string
  description = "The deployment environment (dev, staging, prod)"
}

variable "app_name" {
  type        = string
  description = "The application name used for resource naming conventions"
}

variable "compartment_id" {
  type        = string
  description = "The OCID of the compartment where networking resources will be created"
}

variable "tags" {
  type        = object({ freeformTags = map(string), definedTags = map(string) })
  description = "Resource tags for cost tracking and organization"
  default     = { "definedTags" = {}, "freeformTags" = { "CreatedBy" = "Terraform" } }
}

variable "vcn_name" {
  type        = string
  description = "The display name suffix for the VCN"
  default     = "vcn-0"
}

variable "cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks for the VCN address space"
  default     = ["10.0.0.0/16"]
}

variable "service_gateway_name" {
  type        = string
  description = "The display name suffix for the Service Gateway. Set to null to skip creation."
  nullable    = true
  default     = "sg-0"
}

variable "nat_gateway_name" {
  type        = string
  description = "The display name suffix for the NAT Gateway. Set to null to skip creation."
  nullable    = true
  default     = "ng-0"
}

variable "security_lists" {
  description = "Map of security list configurations with ingress and egress rules"
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
  nullable = true
  default  = null
}

variable "route_tables" {
  description = "Map of route table configurations with routing rules"
  type = map(set(object({
    network_entity_name = string
    description         = optional(string)
    destination         = optional(string)
    destination_type    = optional(string)
  })))
  default = {
    "routetable-private" = [
      {
        network_entity_name = "svcgw"
        destination         = "all-sin-services-in-oracle-services-network"
        destination_type    = "SERVICE_CIDR_BLOCK"
        description         = "Rule for traffic to OCI services"
      },
      {
        network_entity_name = "natgw"
        destination         = "0.0.0.0/0"
        destination_type    = "CIDR_BLOCK"
        description         = "Rule for traffic to Internet"
      }
    ]
  }
}

variable "subnets" {
  description = "Map of subnet configurations including CIDR blocks, route tables, and security settings"
  type = map(object({
    cidr_block                 = string
    dhcp_options_name          = optional(string)
    prohibit_internet_ingress  = optional(bool)
    prohibit_public_ip_on_vnic = optional(bool, true)
    route_table_name           = optional(string)
    dhcp_options_id            = optional(string)
    security_list_names        = optional(list(string))
  }))
  default = {
    "subnet-oke-apiendpoint" = {
      cidr_block       = "10.0.0.0/30"
      route_table_name = "routetable-private"
    },
    "subnet-oke-workernode" = {
      cidr_block       = "10.0.1.0/24"
      route_table_name = "routetable-private"
    },
    "subnet-oke-serviceloadbalancer" = {
      cidr_block       = "10.0.2.0/24"
      route_table_name = "routetable-private"
    },
    "subnet-bastion" = {
      cidr_block       = "10.0.3.0/24"
      route_table_name = "routetable-private"
    },
    "subnet-mysql" = {
      cidr_block       = "10.0.4.0/24"
      route_table_name = "routetable-private"
    },
    "subnet-apigateway" = {
      cidr_block       = "10.0.5.0/24"
      route_table_name = "routetable-private"
    }
  }
}

variable "nsgs" {
  description = "Map of Network Security Group configurations with security rules"
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
      },
      {
        direction        = "EGRESS"
        protocol         = "6"
        destination_type = "CIDR_BLOCK"
        destination      = "10.0.2.0/24"
        description      = "Allow bastion to worker nodes communication."
        tcp_options = {
          destination_port_range = {
            min = 443
            max = 443
          }
        }
      },
    ]
    "nsg-oke-serviceloadbalancer" = [
      {
        direction   = "INGRESS"
        protocol    = "6"
        source_type = "CIDR_BLOCK"
        source      = "10.0.0.0/16"
        description = "Allow all ingress from VCN. Enhanced later"
      },
      {
        direction   = "INGRESS"
        protocol    = "1"
        source_type = "CIDR_BLOCK"
        source      = "10.0.0.0/16"
        description = "Path Discovery for worker nodes"
        icmp_options = {
          type = 3
          code = 4
        }
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
            min = 10256
            max = 10256
          }
        }
      },
      # {
      #   direction        = "EGRESS"
      #   protocol         = "6"
      #   destination_type = "CIDR_BLOCK"
      #   destination      = "10.0.1.0/24"
      #   description      = "Allow OCI load balancer or network load balancer to communicate with kube-proxy on worker nodes."
      #   tcp_options = {
      #     destination_port_range = {
      #       min = 12256
      #       max = 12256
      #     }
      #   }
      # }
    ]
    "nsg-oke-workernode" = [
      {
        direction   = "INGRESS"
        protocol    = "6"
        source_type = "CIDR_BLOCK"
        source      = "10.0.0.0/30"
        description = "Allow Kubernetes API endpoint to communicate with worker nodes."
        tcp_options = {
          destination_port_range = {
            min = 12250
            max = 12250
          }
        }
      },
      {
        direction   = "INGRESS"
        protocol    = "6"
        source_type = "CIDR_BLOCK"
        source      = "10.0.0.0/30"
        description = "Allow Kubernetes API endpoint to communicate with worker nodes."
        tcp_options = {
          destination_port_range = {
            min = 10250
            max = 10250
          }
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
            min = 30000
            max = 32767
          }
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
        protocol    = "1"
        source_type = "CIDR_BLOCK"
        source      = "10.0.0.0/16"
        description = "Path Discovery"
        icmp_options = {
          type = 3
          code = 4
        }
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
        description      = "Allow nodes to communicate with OCI services"
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
      }
    ]
    "nsg-oke-apiendpoint" = [
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
        source      = "10.0.3.0/24"
        description = "Bastion to Kubernetes API endpoint communication."
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
        protocol    = "6"
        source_type = "CIDR_BLOCK"
        source      = "10.0.1.0/24"
        description = "Kubernetes worker to Kubernetes API endpoint communication."
        tcp_options = {
          destination_port_range = {
            min = 10250
            max = 10250
          }
        }
      },
      {
        direction   = "INGRESS"
        protocol    = "1"
        source_type = "CIDR_BLOCK"
        source      = "10.0.0.0/16"
        description = "Path Discovery for worker nodes"
        icmp_options = {
          type = 3
          code = 4
        }
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
        description      = "Allow Kubernetes control plane to communicate with OCI Services"
      },
      {
        direction        = "EGRESS"
        protocol         = "6"
        destination_type = "CIDR_BLOCK"
        destination      = "10.0.1.0/24"
        description      = "Allow Kubernetes control plane to communicate with Worker Nodes"
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
        destination      = "10.0.1.0/24"
        description      = "Allow Kubernetes control plane to communicate with Worker Nodes"
        tcp_options = {
          destination_port_range = {
            min = 10250
            max = 10250
          }
        }
      }
    ]
    "nsg-mysql" = [
      {
        direction   = "INGRESS"
        protocol    = "6"
        source_type = "CIDR_BLOCK"
        source      = "10.0.1.0/24"
        description = "Kubernetes worker to database"
        tcp_options = {
          destination_port_range = {
            min = 3306
            max = 3306
          }
        }
      },
      {
        direction   = "INGRESS"
        protocol    = "6"
        source_type = "CIDR_BLOCK"
        source      = "10.0.3.0/24"
        description = "Bastion to database"
        tcp_options = {
          destination_port_range = {
            min = 3306
            max = 3306
          }
        }
      },
      {
        direction        = "EGRESS"
        protocol         = "6"
        destination_type = "SERVICE_CIDR_BLOCK"
        destination      = "all-sin-services-in-oracle-services-network"
        description      = "Allow nodes to communicate with OCI services"
      }
    ]
    "nsg-apigateway" = [
      {
        direction   = "INGRESS"
        protocol    = "6"
        source_type = "CIDR_BLOCK"
        source      = "10.0.0.0/16"
        description = "Allow all ingress from VCN. Enhanced later"
        tcp_options = {
          destination_port_range = {
            min = 443
            max = 443
          }
        }
      },
      {
        direction   = "INGRESS"
        protocol    = "1"
        source_type = "CIDR_BLOCK"
        source      = "10.0.0.0/16"
        description = "Path Discovery for worker nodes"
        icmp_options = {
          type = 3
          code = 4
        }
      },
      {
        direction        = "EGRESS"
        protocol         = "6"
        destination_type = "CIDR_BLOCK"
        destination      = "10.0.2.0/24"
        description      = "API Gateway to Load balancer"
        tcp_options = {
          destination_port_range = {
            min = 443
            max = 443
          }
        }
      },
    ]
  }
}




