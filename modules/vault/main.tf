resource "oci_kms_vault" "vault" {
  #Required
  compartment_id = var.compartment_id
  display_name   = var.vault_name
  vault_type     = var.vault_type

  # tags
  defined_tags  = var.tags.definedTags
  freeform_tags = var.tags.freeformTags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}

resource "oci_kms_key" "master_keys" {
  for_each                 = var.master_keys
  compartment_id           = var.compartment_id
  management_endpoint      = oci_kms_vault.vault.management_endpoint
  display_name             = each.key
  protection_mode          = each.value.protection_mode
  is_auto_rotation_enabled = each.value.is_auto_rotation_enabled

  key_shape {
    algorithm = each.value.algorithm
    length    = each.value.length
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

  # tags
  defined_tags  = var.tags.definedTags
  freeform_tags = var.tags.freeformTags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
  depends_on = [oci_kms_vault.vault]
}

resource "oci_kms_generated_key" "generated_keys" {
  for_each              = var.generated_keys
  crypto_endpoint       = oci_kms_vault.vault.crypto_endpoint
  include_plaintext_key = each.value.include_plaintext_key
  key_id                = [for key in oci_kms_key.master_keys : key.id if key.display_name == each.value.master_key_name][0]

  key_shape {
    algorithm = each.value.algorithm
    length    = each.value.length
    curve_id  = each.value.curve_id
  }

  associated_data = each.value.associated_data
  logging_context = each.value.logging_context
}

resource "oci_vault_secret" "secrets" {
  for_each       = var.secrets
  compartment_id = var.compartment_id
  key_id         = [for key in oci_kms_key.master_keys : key.id if key.display_name == each.value.key_name][0]
  vault_id       = oci_kms_vault.vault.id
  secret_name    = each.key

  description            = each.value.description
  enable_auto_generation = each.value.enable_auto_generation
  metadata               = each.value.metadata

  dynamic "secret_generation_context" {
    for_each = each.value.enable_auto_generation == true ? [1] : []
    content {
      generation_template = each.value.generation_template
      generation_type     = each.value.generation_type
      passphrase_length   = each.value.passphrase_length
      secret_template     = each.value.secret_template
    }
  }

  # tags
  defined_tags  = var.tags.definedTags
  freeform_tags = var.tags.freeformTags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
  depends_on = [oci_kms_key.master_keys]
}