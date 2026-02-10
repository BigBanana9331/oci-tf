data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = var.ad_number
}

data "oci_core_vcns" "vcns" {
  compartment_id = var.compartment_ocid
  display_name   = join("-", [var.environment, var.vcn_name])
}

data "oci_core_subnets" "subnets" {
  compartment_id = var.compartment_ocid
  vcn_id         = data.oci_core_vcns.vcns.virtual_networks[0].id
}

data "oci_core_network_security_groups" "network_security_groups" {
  compartment_id = var.compartment_ocid
  vcn_id         = data.oci_core_vcns.vcns.virtual_networks[0].id
}

data "oci_containerengine_node_pool_option" "node_pool_option" {
  node_pool_option_id = var.node_pool_option_id
  node_pool_os_arch   = var.node_pool_os_arch
  node_pool_os_type   = var.node_pool_os_type
}

data "oci_kms_vaults" "vaults" {
  compartment_id = var.vault_compartment_id
  filter {
    name   = "display_name"
    values = [var.vault_name]
  }
}

data "oci_kms_keys" "keys" {
  compartment_id      = var.vault_compartment_id
  management_endpoint = data.oci_kms_vaults.vaults.vaults[0].management_endpoint
}

data "oci_vault_secrets" "admin_password_secret" {
  compartment_id = var.vault_compartment_id
  name           = var.admin_password_secret_name
  vault_id       = data.oci_kms_vaults.vaults.vaults[0].id
}

data "oci_secrets_secretbundle" "admin_password_secretbundle" {
  secret_id = data.oci_vault_secrets.admin_password_secret.secrets[0].id
}