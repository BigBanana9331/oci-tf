terraform {
  required_version = ">= 1.5.7"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.30"
    }
  }
}


variable "compartment_id" {
  type = string
}

variable "tags" {
  type    = object({ freeformTags = map(string), definedTags = map(string) })
  default = { "definedTags" = {}, "freeformTags" = { "CreatedBy" = "Terraform" } }
}

variable "vcn_cidr_blocks" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "vcn_name" {
  type    = string
  default = "dev-vcn"
}

variable "nat_gateway_name" {
  type    = string
  default = "dev-ng"
}

variable "service_gateway_name" {
  type    = string
  default = "dev-sg"
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
  nullable = true
  default  = null
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
      # {
      #   network_entity_name = "natgw"
      #   destination         = "0.0.0.0/0"
      #   destination_type    = "CIDR_BLOCK"
      #   description         = "Rule for traffic to internet"
      # },
      {
        network_entity_name = "svcgw"
        destination         = "all-sin-services-in-oracle-services-network"
        destination_type    = "SERVICE_CIDR_BLOCK"
        description         = "Rule for traffic to OCI services"
      }
    ],
  }
}

variable "subnets" {
  type = map(object({
    cidr_block                 = string
    dhcp_options_name          = optional(string)
    prohibit_internet_ingress  = optional(bool)
    prohibit_public_ip_on_vnic = optional(bool, true)
    route_table_name           = optional(string)
    security_list_names        = optional(list(string))
  }))
  default = {
    "dev-subnet-oke-apiendpoint" = {
      cidr_block          = "10.0.0.0/30"
      route_table_name    = "routetable-private"
      security_list_names = ["seclist-default"]
    },
    "dev-subnet-oke-workernode" = {
      cidr_block          = "10.0.1.0/24"
      route_table_name    = "routetable-private"
      security_list_names = ["seclist-default"]
    },
    "dev-subnet-oke-serviceloadbalancer" = {
      cidr_block          = "10.0.2.0/24"
      route_table_name    = "routetable-private"
      security_list_names = ["seclist-default"]
    },
    "dev-subnet-bastion" = {
      cidr_block          = "10.0.3.0/24"
      route_table_name    = "routetable-private"
      security_list_names = ["seclist-default"]
    },
    "dev-subnet-mysql" = {
      cidr_block          = "10.0.4.0/24"
      route_table_name    = "routetable-private"
      security_list_names = ["seclist-default"]
    },
    "dev-subnet-apigateway" = {
      cidr_block          = "10.0.5.0/24"
      route_table_name    = "routetable-private"
      security_list_names = ["seclist-default"]
    },
    "dev-subnet-privateendpoint" = {
      cidr_block          = "10.0.6.0/24"
      route_table_name    = "routetable-private"
      security_list_names = ["seclist-default"]
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
  default = {
    "dev-nsg-bastion" = [
      {
        direction   = "INGRESS"
        protocol    = "all"
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
    ]
    "dev-nsg-oke-serviceloadbalancer" = [
      {
        direction   = "INGRESS"
        protocol    = "all"
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
    "dev-nsg-oke-workernode" = [
      {
        direction   = "INGRESS"
        protocol    = "6"
        source_type = "CIDR_BLOCK"
        source      = "10.0.0.0/30"
        description = "Allow Kubernetes API endpoint to communicate with worker nodes."
      },
      {
        direction   = "INGRESS"
        protocol    = "6"
        source_type = "CIDR_BLOCK"
        source      = "10.0.2.0/24"
        description = "Allow OCI load balancer or network load balancer to communicate with kube-proxy on worker nodes."
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
      }
    ]
    "dev-nsg-oke-apiendpoint" = [
      {
        direction   = "INGRESS"
        protocol    = "6"
        source_type = "CIDR_BLOCK"
        source      = "10.0.0.0/16"
        description = "All VCN to Kubernetes API endpoint communication."
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
        destination      = "10.0.0.0/16"
        description      = "All traffic to VCN. Enhanced later"
      }
    ]
    "dev-nsg-mysql" = [
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
        direction   = "INGRESS"
        protocol    = "6"
        source_type = "CIDR_BLOCK"
        source      = "10.0.6.0/24"
        description = "Private Endpoint to database"
        tcp_options = {
          destination_port_range = {
            min = 3306
            max = 3306
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
        destination      = "10.0.0.0/16"
        description      = "Allow to communicate within VCN. Enhance later"
      },
    ]
    "dev-nsg-privateendpoint" = [
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
        destination      = "10.0.0.0/30"
        description      = "Allow pe to Kubernetes API endpoint communication."
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
        description      = "Allow pe to worker nodes communication."
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
        destination_type = "SERVICE_CIDR_BLOCK"
        destination      = "all-sin-services-in-oracle-services-network"
        description      = "Allow pe to communicate with OCI services"
      }
    ]
    "dev-nsg-apigateway" = [
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
        protocol         = "1"
        destination_type = "CIDR_BLOCK"
        destination      = "0.0.0.0/0"
        description      = "Path Discovery."
        icmp_options = {
          type = 3
          code = 4
        }
      },
    ]
  }
}




