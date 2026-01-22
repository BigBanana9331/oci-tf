resource "oci_kms_vault" "vault" {
  #Required
  compartment_id = var.compartment_id
  display_name   = var.vault_name
  vault_type     = var.vault_type
  defined_tags   = var.defined_tags
}

resource "oci_kms_key" "keys" {
  for_each                 = var.keys
  compartment_id           = var.compartment_id
  management_endpoint      = oci_kms_vault.vault.management_endpoint
  display_name             = each.key
  protection_mode          = each.value.protection_mode
  is_auto_rotation_enabled = each.value.is_auto_rotation_enabled
  defined_tags             = var.defined_tags

  key_shape {
    algorithm = each.value.key_shape_algorithm
    length    = each.value.key_shape_length
  }

  dynamic "auto_key_rotation_details" {
    for_each = each.value.is_auto_rotation_enabled == true ? [1] : []
    content {
      last_rotation_message     = each.value.last_rotation_message
      last_rotation_status      = each.value.last_rotation_status
      rotation_interval_in_days = each.value.rotation_interval_in_days
      time_of_last_rotation     = each.value.time_of_last_rotation
      time_of_next_rotation     = each.value.time_of_next_rotation
      time_of_schedule_start    = each.value.time_of_schedule_start
    }
  }
}