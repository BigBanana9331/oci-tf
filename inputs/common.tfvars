# =============================================================================
# Common Configuration - Shared across all environments
# =============================================================================
# This file contains configuration values that are identical across dev/staging/prod.
# Environment-specific values should be in dev.tfvars, staging.tfvars, or prod.tfvars
# 
# Usage: terraform plan -var-file="inputs/common.tfvars" -var-file="inputs/dev.tfvars"
# =============================================================================

# Default tags applied to all resources
tags = {
  definedTags = {}
  freeformTags = {
    CreatedBy = "Terraform"
    Project   = "OCI Infrastructure"
    ManagedBy = "IaC"
  }
}
