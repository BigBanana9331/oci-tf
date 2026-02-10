vcn_name = "vcn"

bastion = {
  subnet_name                = "subnet-bastion"
  bastion_name               = "bastion-0"
  max_session_ttl_in_seconds = 3600
}

apigw = {
  subnet_name  = "subnet-apigateway"
  gateway_name = "api-gateway-0"
  nsg_names    = []
}

oke = {
  vcn_name                 = "vcn"
  cluster_name             = "oke"
  cluster_type             = "ENHANCED_CLUSTER"
  kubernetes_version       = "v1.34.1"
  cluster_subnet_name      = "subnet-oke-apiendpoint"
  loadbalancer_subnet_name = "subnet-oke-loadbalancer"
  worker_subnet_name       = "subnet-oke-worker"
  endpoint_nsg_names       = ["nsg-oke-api-endpoint"]
  cni_type                 = "FLANNEL_OVERLAY"
  services_cidr            = "10.96.0.0/16"
  pods_cidr                = "10.244.0.0/16"
  kms_key_name                 = "encryption-key"

  node_pools = {
    "pool" = {
      node_shape                          = "VM.Standard.E5.Flex"
      node_shape_ocpus                    = 1
      node_shape_memory_in_gbs            = 8
      node_pool_size                      = 1
      cni_type                            = "FLANNEL_OVERLAY"
      node_nsg_names                      = ["nsg-oke-workernode"]
      is_pv_encryption_in_transit_enabled = true
      # key_name                            = "encryption-key"
    }
  }

  autoscaler = {
    is_enabled = true
    min_node   = 1
    max_node   = 2
  }
}

mysql = {
  vcn_name                = "vcn"
  subnet_name             = "subnet-mysql"
  nsg_names               = []
  shape_name              = "MySQL.2"
  display_name            = "mysql"
  data_storage_size_in_gb = 50
  is_highly_available     = false
  key_name                = "encryption-key"
}
