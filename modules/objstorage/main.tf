
data "oci_objectstorage_namespace" "namespace" {
  compartment_id = var.compartment_id
}

data "oci_kms_vaults" "vaults" {
  compartment_id = var.compartment_id
  filter {
    name   = "display_name"
    values = [var.vault_name]
  }
}

data "oci_kms_keys" "keys" {
  count               = var.key_name != null ? 1 : 0
  compartment_id      = var.compartment_id
  management_endpoint = data.oci_kms_vaults.vaults.vaults[0].management_endpoint
  filter {
    name   = "display_name"
    values = [var.key_name]
  }
}

resource "oci_objectstorage_bucket" "buckets" {
  for_each       = var.buckets
  compartment_id = var.compartment_id
  name           = each.value
  namespace      = data.oci_objectstorage_namespace.namespace.namespace
  kms_key_id     = var.key_name != null && length(data.oci_kms_keys.keys) > 0 ? data.oci_kms_keys.keys.keys[0].id : null
  defined_tags   = var.tags.definedTags
  freeform_tags  = var.tags.freeformTags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}