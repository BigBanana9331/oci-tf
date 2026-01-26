terraform {
  required_version = ">= 1.5.7"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "7.30.0"
    }
  }
}

resource "oci_logging_log_group" "log_group" {
  compartment_id = var.compartment_id
  display_name   = var.log_group_name
  description    = var.log_group_description

  # tags
  defined_tags  = var.tags.definedTags
  freeform_tags = var.tags.freeformTags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}