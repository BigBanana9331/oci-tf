resource "oci_identity_tag_namespace" "namespace" {
  compartment_id = var.compartment_id
  name           = var.namespace.name
  description    = var.namespace.description
  is_retired     = var.namespace.is_retired
}

resource "oci_identity_tag" "tags" {
  for_each         = var.namespace.tags
  tag_namespace_id = oci_identity_tag_namespace.namespace.id
  name             = each.key
  description      = each.value.description
  is_cost_tracking = each.value.is_cost_tracking
  is_retired       = each.value.is_retired
}