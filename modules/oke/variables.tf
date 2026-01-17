variable "tenancy_ocid" {}

variable "compartment_id" {}

variable "vcn_cidr_blocks" {
  type = list(string)
}

variable "vcn_display_name" {
  type    = string
  default = "acme-dev-vcn"
}

variable "internet_gateway_enabled" {
  type    = bool
  default = true
}

variable "internet_gateway_display_name" {
  type    = string
  default = "internet-gateway-0"
}

variable "nat_gateway_display_name" {
  type    = string
  default = "nat-gateway-0"
}

variable "service_gateway_display_name" {
  type    = string
  default = "service-gateway-0"
}

variable "service_gateway_service_names" {
  type = map(string)
}

variable "dhcp_options_display_name" {
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
      egress_security_rules  = []
      ingress_security_rules = []
    }
    seclist-workernodes = {
      egress_security_rules  = []
      ingress_security_rules = []
    }
    seclist-loadbalancers = {
      egress_security_rules = [
        {
          protocol    = "all"
          source      = "10.0.1.0/24"
          description = "Load balancer to worker nodes node ports."
          source_type = "CIDR_BLOCK"
          stateless   = false
          tcp_options = {
            min = 30000
            max = 32767
          }
        },
        {
          protocol    = "all"
          source      = "10.0.1.0/24"
          description = "Allow load balancer to communicate with kube-proxy on worker nodes."
          source_type = "CIDR_BLOCK"
          stateless   = false
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
          stateless   = false
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
          stateless        = false
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
          stateless        = false
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
  type = map(object({
    compartment_id = string
    vcn_id         = string
    display_name   = string

    route_rules = optional(set(object({
      network_entity_id = string
      description       = optional(string)
      destination       = optional(string)
      destination_type  = optional(string)
    })))
  }))
}

variable "subnets" {
  type = map(object({
    compartment_id            = string
    vcn_id                    = string
    cidr_block                = string
    dhcp_options_id           = optional(string)
    prohibit_internet_ingress = optional(bool, false)
    route_table_id            = optional(string)
    security_list_ids         = optional(list(string))
  }))
}

variable "cluster_name" {
  type    = string
  default = "oke-0"
}

variable "cluster_type" {
  type    = string
  default = "BASIC_CLUSTER"
}

variable "kubernetes_version" {
  type    = string
  default = "v1.34.1"
}

variable "pods_cidr" {
  type    = string
  default = "10.244.0.0/16"
}

variable "services_cidr" {
  type    = string
  default = "10.96.0.0/16"
}