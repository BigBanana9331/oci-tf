# =============================================================================
# TFLint Configuration for OCI Terraform Project
# =============================================================================
# Run: tflint --init && tflint
# Docs: https://github.com/terraform-linters/tflint

config {
  # Enable all available plugins
  plugin_dir = "~/.tflint.d/plugins"
  
  # Fail on warning
  force = false
  
  # Warn about values not defined in variables
  disabled_by_default = false
}

# =============================================================================
# Terraform Rules
# =============================================================================

# Disallow // comments in favor of #
rule "terraform_comment_syntax" {
  enabled = true
}

# Ensure consistent naming conventions for resources
rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

# Ensure terraform and provider version constraints are specified
rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

# Enforce terraform fmt
rule "terraform_standard_module_structure" {
  enabled = true
}

# Variables must have type
rule "terraform_typed_variables" {
  enabled = true
}

# Unused declarations
rule "terraform_unused_declarations" {
  enabled = true
}

# Unused required providers
rule "terraform_unused_required_providers" {
  enabled = true
}

# Workspace naming
rule "terraform_workspace_remote" {
  enabled = true
}

# Deprecated interpolation syntax
rule "terraform_deprecated_interpolation" {
  enabled = true
}

# Deprecated index notation
rule "terraform_deprecated_index" {
  enabled = true
}

# Empty list equality checks
rule "terraform_empty_list_equality" {
  enabled = true
}

# Prefer module sources with version constraints
rule "terraform_module_pinned_source" {
  enabled = true
  
  style                  = "flexible"
  default_branches       = ["main", "master"]
}

# Variables should have descriptions
rule "terraform_documented_variables" {
  enabled = true
}

# Outputs should have descriptions
rule "terraform_documented_outputs" {
  enabled = true
}
