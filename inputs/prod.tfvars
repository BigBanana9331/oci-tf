vcns = {
  "vcn-0" = {
    cidr_blocks = ["10.0.0.0/16"]
    route_tables = {
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
    subnets = {
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
    nsgs = {
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
        }
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
}