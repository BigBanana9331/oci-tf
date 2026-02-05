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

# data "oci_containerengine_node_pool_option" "node_pool_option" {
#   node_pool_option_id   = var.node_pool_option_id
#   node_pool_k8s_version = var.node_pool_k8s_version
#   node_pool_os_arch     = var.node_pool_os_arch
#   node_pool_os_type     = var.node_pool_os_type
# }

# data "oci_kms_vaults" "vaults" {
#   compartment_id = var.compartment_id
# }

# data "oci_kms_keys" "keys" {
#   compartment_id      = var.compartment_id
#   management_endpoint = [for vault in data.oci_kms_vaults.vaults.vaults : vault.management_endpoint if vault.display_name == var.vault_name][0]
# }

# data "oci_vault_secrets" "secrets" {
#   compartment_id = var.compartment_id
#   name           = var.admin_password_secret_name
#   vault_id       = [for vault in data.oci_kms_vaults.vaults.vaults : vault.id if vault.display_name == var.vault_name][0]
# }


# data "oci_secrets_secretbundle" "secretbundle" {
#   secret_id = data.oci_vault_secrets.secrets.secrets[0].id
# }

# output "secretbundle" {
#   value = data.oci_secrets_secretbundle.secretbundle
# }