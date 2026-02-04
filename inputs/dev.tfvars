# bastion = {
#   vcn_name                   = "vcn"
#   subnet_name                = "subnet-bastion"
#   bastion_name               = "bastion-0"
#   max_session_ttl_in_seconds = 3600
# }

# oke = {
#   vcn_name                 = "vcn"
#   cluster_name             = "oke"
#   cluster_type             = "ENHANCED_CLUSTER"
#   kubernetes_version       = "v1.34.1"
#   cluster_subnet_name      = "subnet-oke-api-endpoint"
#   loadbalancer_subnet_name = "subnet-oke-loadbalancer"
#   worker_subnet_name       = "subnet-oke-worker"
#   endpoint_nsg_names       = ["nsg-oke-api-endpoint"]
#   cni_type                 = "FLANNEL_OVERLAY"
#   services_cidr            = "10.96.0.0/16"
#   pods_cidr                = "10.244.0.0/16"

#   log_group = {
#     name = "oke-loggroup"
#   }

#   instance_dynamic_group = {
#     name        = "nodes-dg"
#     description = "Nodepool dyanmic group"
#   }

#   policy = {
#     name = "oke-policy"
#   }
#   unified_agent_configuration = {
#     name               = "nodes-uac"
#     is_enabled         = true
#     configuration_type = "LOGGING"
#     log_object_name    = "customlog-oke"
#     source = {
#       name        = "worker-logtail"
#       source_type = "LOG_TAIL"
#       paths       = ["/var/log/containers/*", "/var/log/pods/*"]
#       parser_type = "NONE"
#     }
#   }

#   logs = {
#     "servicelog-oke" = {
#       type        = "SERVICE"
#       source_type = "OCISERVICE"
#       service     = "oke-k8s-cp-prod"
#       category    = "all-service-logs"
#     }
#     "customlog-oke" = {
#       type = "CUSTOM"
#     }
#   }

#   node_pools = {
#     "pool" = {
#       node_shape                          = "VM.Standard.E5.Flex"
#       node_shape_ocpus                    = 1
#       node_shape_memory_in_gbs            = 8
#       node_pool_size                      = 1
#       cni_type                            = "FLANNEL_OVERLAY"
#       node_nsg_names                      = ["nsg-oke-workernode"]
#       is_pv_encryption_in_transit_enabled = false
#     }
#   }

#   autoscaler = {
#     is_enabled = true
#     min_node   = 1
#     max_node   = 2
#   }
# }