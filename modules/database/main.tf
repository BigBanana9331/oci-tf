data "oci_identity_availability_domains" "availability_domains" {
  compartment_id = var.tenancy_ocid
}

data "oci_identity_compartment" "compartment" {
  id = var.compartment_id
}

data "oci_core_vcns" "vcns" {
  compartment_id = var.compartment_id
  display_name   = join("-", [var.environment,var.vcn_name])
}

data "oci_core_subnets" "subnets" {
  compartment_id = var.compartment_id
  vcn_id         = data.oci_core_vcns.vcns.virtual_networks[0].id
}

data "oci_core_network_security_groups" "network_security_groups" {
  compartment_id = var.compartment_id
  vcn_id         = data.oci_core_vcns.vcns.virtual_networks[0].id
}

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

resource "oci_identity_policy" "policy" {
  compartment_id = var.compartment_id
  description    = var.policy.name
  name           = join("-", [var.environment, var.policy.name])
  statements = [
    "Allow any-user to use key-delegate in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type = 'mysqldbsystem', request.resource.compartment.id='${var.compartment_id}'}",
    "Allow any-user to {VOLUME_UPDATE, VOLUME_INSPECT, VOLUME_CREATE, VOLUME_BACKUP_READ, VOLUME_BACKUP_UPDATE, BUCKET_UPDATE, VOLUME_GROUP_BACKUP_CREATE, VOLUME_BACKUP_COPY, VOLUME_BACKUP_CREATE, TAG_NAMESPACE_INSPECT, TAG_NAMESPACE_USE} in compartment ${data.oci_identity_compartment.compartment.name} where request.principal.type = 'mysqldbsystem'",
    "Allow any-user to associate keys in compartment ${data.oci_identity_compartment.compartment.name} with volumes in compartment ${data.oci_identity_compartment.compartment.name} where request.principal.type = 'mysqldbsystem'",
    "Allow any-user to associate keys in compartment ${data.oci_identity_compartment.compartment.name} with volume-backups in compartment ${data.oci_identity_compartment.compartment.name} where request.principal.type = 'mysqldbsystem'",
    "Allow any-user to associate keys in compartment ${data.oci_identity_compartment.compartment.name} with buckets in compartment ${data.oci_identity_compartment.compartment.name} where request.principal.type = 'mysqldbsystem'",
    "Allow any-user to {NETWORK_SECURITY_GROUP_UPDATE_MEMBERS} in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type='mysqldbsystem', request.resource.compartment.id='${var.compartment_id}'}",
    "Allow any-user to {VNIC_CREATE, VNIC_UPDATE, VNIC_ASSOCIATE_NETWORK_SECURITY_GROUP, VNIC_DISASSOCIATE_NETWORK_SECURITY_GROUP} in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type='mysqldbsystem', request.resource.compartment.id='${var.compartment_id}'}",
    "Allow any-user to {SECURITY_ATTRIBUTE_NAMESPACE_USE, VNIC_UPDATE, VNIC_CREATE} in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type='mysqldbsystem', request.resource.compartment.id='${var.compartment_id}'}",
    "Allow any-user to read leaf-certificate-family in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type = 'mysqldbsystem', request.resource.compartment.id='${var.compartment_id}'}"
  ]

  defined_tags  = var.tags.definedTags
  freeform_tags = var.tags.freeformTags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}



resource "oci_mysql_mysql_db_system" "mysql_db_system" {
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[0].name
  display_name        = join("-", [var.environment, var.display_name])
  description         = var.description

  is_highly_available     = var.is_highly_available
  shape_name              = var.shape_name
  data_storage_size_in_gb = var.data_storage_size_in_gb
  # admin_username          = var.admin_username
  # admin_password          = base64decode(data.oci_secrets_secretbundle.secretbundle.secret_bundle_content[0].content)

  subnet_id = [for subnet in data.oci_core_subnets.subnets.subnets : subnet.id if subnet.display_name == join("-", [var.environment, var.subnet_name])][0]
  nsg_ids = flatten([for nsg in data.oci_core_network_security_groups.network_security_groups.network_security_groups :
  [for nsg_name in var.nsg_names : nsg.id if nsg.display_name == join("-", [var.environment, nsg_name])]])

  mysql_version       = var.mysql_version
  access_mode         = var.access_mode
  database_mode       = var.database_mode
  crash_recovery      = var.crash_recovery
  database_management = var.database_management
  port                = var.port
  port_x              = var.port_x
  ip_address          = var.ip_address
  hostname_label      = join("-", [var.environment, var.hostname_label])

  dynamic "encrypt_data" {
    for_each = var.key_generation_type != null ? [1] : []
    content {
      key_generation_type = var.key_generation_type
      key_id              = [for key in data.oci_kms_keys.keys.keys : key.id if key.display_name == var.key_name][0]
    }
  }

  dynamic "secure_connections" {
    for_each = var.certificate_generation_type != null ? [1] : []
    content {
      certificate_generation_type = var.certificate_generation_type
      certificate_id              = var.certificate_id
    }
  }

  dynamic "data_storage" {
    for_each = var.data_storage != null ? [1] : []
    content {
      is_auto_expand_storage_enabled = var.data_storage.is_auto_expand_storage_enabled
      max_storage_size_in_gbs        = var.data_storage.max_storage_size_in_gbs
    }
  }

  dynamic "backup_policy" {
    for_each = var.backup_policy != null ? [1] : []
    content {
      is_enabled        = var.backup_policy.is_enabled
      retention_in_days = var.backup_policy.retention_in_days
      window_start_time = var.backup_policy.window_start_time
      soft_delete       = var.backup_policy.soft_delete
      dynamic "pitr_policy" {
        for_each = var.backup_policy.pitr_enabled != null ? [1] : []
        content {
          is_enabled = var.backup_policy.pitr_enabled
        }
      }
    }
  }

  dynamic "deletion_policy" {
    for_each = var.deletion_policy != null ? [1] : []
    content {
      automatic_backup_retention = var.deletion_policy.automatic_backup_retention
      final_backup               = var.deletion_policy.final_backup
      is_delete_protected        = var.deletion_policy.is_delete_protected
    }
  }

  dynamic "read_endpoint" {
    for_each = var.read_endpoint != null ? [1] : []
    content {
      exclude_ips                  = var.read_endpoint.exclude_ips
      is_enabled                   = var.read_endpoint.is_enabled
      read_endpoint_hostname_label = var.read_endpoint.hostname_label
      read_endpoint_ip_address     = var.read_endpoint.ip_address
    }
  }

  dynamic "rest" {
    for_each = var.rest != null ? [1] : []
    content {
      configuration = var.rest.configuration
      port          = var.rest.port
    }
  }

  dynamic "database_console" {
    for_each = var.database_console != null ? [1] : []
    content {
      status = var.database_console.status
      port   = var.database_console.port
    }
  }
  dynamic "maintenance" {
    for_each = var.maintenance != null ? [1] : []
    content {
      window_start_time = var.maintenance.window_start_time
      # maintenance_schedule_type = var.maintenance.maintenance_schedule_type
      # version_preference        = var.maintenance.version_preference
      # version_track_preference  = var.maintenance.version_track_preference
    }
  }

  defined_tags  = var.tags.definedTags
  freeform_tags = var.tags.freeformTags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }

  depends_on = [oci_identity_policy.policy]
}