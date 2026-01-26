terraform {
  required_version = ">= 1.5.7"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "7.30.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.8.0"
    }
  }
}



data "oci_identity_availability_domains" "availability_domains" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_vcns" "vcns" {
  compartment_id = var.compartment_id
  display_name   = var.vcn_name
}

data "oci_core_subnets" "subnets" {
  compartment_id = var.compartment_id
  vcn_id         = data.oci_core_vcns.vcns.virtual_networks[0].id
}

data "oci_core_network_security_groups" "network_security_groups" {
  compartment_id = var.compartment_id
  vcn_id         = data.oci_core_vcns.vcns.virtual_networks[0].id
}

data "oci_kms_vaults" "vaults" {
  compartment_id = var.compartment_id
}

data "oci_kms_keys" "keys" {
  compartment_id      = var.compartment_id
  management_endpoint = [for vault in data.oci_kms_vaults.vaults.vaults : vault.management_endpoint if vault.display_name == var.vault_name][0]
}

resource "random_password" "password" {
  length           = 32
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  override_special = "#$%&*-_=+:?"
}

resource "oci_vault_secret" "admin_password" {
  compartment_id = var.compartment_id
  key_id         = [for key in data.oci_kms_keys.keys.keys : key.id if key.display_name == var.key_name][0]
  vault_id       = [for vault in data.oci_kms_vaults.vaults.vaults : vault.id if vault.display_name == var.vault_name][0]
  secret_name    = var.admin_password.display_name
  description    = var.admin_password.description
  metadata       = var.admin_password.metadata

  secret_content {
    content      = base64encode(random_password.password.result)
    content_type = var.admin_password.content_type
    name         = var.admin_password.name
    stage        = var.admin_password.stage
  }
  # tags
  defined_tags  = var.tags.definedTags
  freeform_tags = var.tags.freeformTags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}

resource "oci_mysql_mysql_db_system" "mysql_db_system" {
  display_name = var.display_name
  # description         = var.description
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[0].name
  # is_highly_available = var.is_highly_available
  shape_name = var.shape_name
  # mysql_version       = var.mysql_version
  subnet_id = [for subnet in data.oci_core_subnets.subnets.subnets : subnet.id if subnet.display_name == var.subnet_name][0]
  # nsg_ids = flatten([for nsg in data.oci_core_network_security_groups.network_security_groups.network_security_groups :
  # [for nsg_name in var.nsg_names : nsg.id if nsg.display_name == nsg_name]])
  # data_storage_size_in_gb = var.data_storage_size_in_gb
  # access_mode             = var.access_mode
  # crash_recovery          = var.crash_recovery
  # database_management     = var.database_management
  # admin_username          = var.admin_username
  # admin_password          = random_password.password.result

  # dynamic "encrypt_data" {
  #   for_each = var.key_generation_type != null ? [1] : []
  #   content {
  #     key_generation_type = var.key_generation_type
  #     key_id              = [for key in data.oci_kms_keys.keys.keys : key.id if key.display_name == var.key_name][0]
  #   }
  # }

  # dynamic "database_console" {
  #   for_each = var.database_console != null ? [1] : []
  #   content {
  #     port   = each.value.port
  #     status = each.value.status
  #   }
  # }

  # data_storage {
  #   is_auto_expand_storage_enabled = var.is_auto_expand_storage_enabled
  #   max_storage_size_in_gbs        = var.max_storage_size_in_gbs
  # }

  # backup_policy {
  #   is_enabled        = var.backup_policy.is_enabled
  #   retention_in_days = var.backup_policy.retention_in_days
  #   window_start_time = var.backup_policy.window_start_time
  # }

  # maintenance {
  #   window_start_time = var.maintenance_window_start_time
  # }

  # tags
  defined_tags  = var.tags.definedTags
  freeform_tags = var.tags.freeformTags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}