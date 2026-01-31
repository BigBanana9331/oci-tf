# =============================================================================
# Provider Configuration
# =============================================================================

# Backend configuration
# Uncomment for OCI Object Storage state management in production:
# terraform {
#   backend "oci" {}
# }

provider "oci" {
  region              = var.region
  config_file_profile = var.oci_config_profile
}
