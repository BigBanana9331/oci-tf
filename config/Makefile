# =============================================================================
# Terraform Makefile
# =============================================================================
# Common operations for managing Terraform infrastructure
# Usage: make <target> [ENV=dev|staging|prod]

# Default environment
ENV ?= dev

# Terraform command
TF := terraform

# Variable files
COMMON_VARS := -var-file=inputs/common.tfvars
ENV_VARS := -var-file=inputs/$(ENV).tfvars
ALL_VARS := $(COMMON_VARS) $(ENV_VARS)

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: help init fmt validate plan apply destroy clean lint docs security

# Default target
help:
	@echo ""
	@echo "$(GREEN)OCI Terraform Infrastructure$(NC)"
	@echo ""
	@echo "Usage: make <target> [ENV=dev|staging|prod]"
	@echo ""
	@echo "Targets:"
	@echo "  $(YELLOW)init$(NC)      - Initialize Terraform working directory"
	@echo "  $(YELLOW)fmt$(NC)       - Format Terraform files"
	@echo "  $(YELLOW)validate$(NC)  - Validate Terraform configuration"
	@echo "  $(YELLOW)plan$(NC)      - Create execution plan"
	@echo "  $(YELLOW)apply$(NC)     - Apply changes"
	@echo "  $(YELLOW)destroy$(NC)   - Destroy infrastructure"
	@echo "  $(YELLOW)clean$(NC)     - Remove .terraform directory"
	@echo "  $(YELLOW)lint$(NC)      - Run TFLint"
	@echo "  $(YELLOW)docs$(NC)      - Generate documentation"
	@echo "  $(YELLOW)security$(NC)  - Run security scans"
	@echo "  $(YELLOW)all$(NC)       - Run fmt, validate, lint, and plan"
	@echo ""
	@echo "Examples:"
	@echo "  make plan ENV=dev"
	@echo "  make apply ENV=prod"
	@echo ""

# Initialize Terraform
init:
	@echo "$(GREEN)Initializing Terraform for $(ENV)...$(NC)"
	$(TF) init -upgrade

# Format Terraform files
fmt:
	@echo "$(GREEN)Formatting Terraform files...$(NC)"
	$(TF) fmt -recursive

# Validate Terraform configuration
validate: init
	@echo "$(GREEN)Validating Terraform configuration...$(NC)"
	$(TF) validate

# Create execution plan
plan: validate
	@echo "$(GREEN)Creating execution plan for $(ENV)...$(NC)"
	$(TF) plan $(ALL_VARS) -out=tfplan.$(ENV)

# Apply changes
apply: plan
	@echo "$(YELLOW)Applying changes for $(ENV)...$(NC)"
	$(TF) apply tfplan.$(ENV)

# Apply without plan (use with caution)
apply-auto:
	@echo "$(RED)Auto-applying changes for $(ENV)...$(NC)"
	$(TF) apply $(ALL_VARS) -auto-approve

# Destroy infrastructure
destroy:
	@echo "$(RED)Destroying infrastructure for $(ENV)...$(NC)"
	$(TF) destroy $(ALL_VARS)

# Clean up Terraform files
clean:
	@echo "$(YELLOW)Cleaning up Terraform files...$(NC)"
	rm -rf .terraform
	rm -rf .terraform.lock.hcl
	rm -f tfplan.*
	rm -f crash.log

# Run TFLint
lint:
	@echo "$(GREEN)Running TFLint...$(NC)"
	tflint --init
	tflint --recursive

# Generate documentation
docs:
	@echo "$(GREEN)Generating documentation...$(NC)"
	terraform-docs markdown table . --output-file README.md
	@for dir in modules/*/; do \
		echo "Generating docs for $$dir"; \
		terraform-docs markdown table "$$dir" --output-file "$$dir/README.md"; \
	done

# Run security scans
security:
	@echo "$(GREEN)Running security scans...$(NC)"
	@echo "Running tfsec..."
	tfsec . --concise-output || true
	@echo ""
	@echo "Running checkov..."
	checkov -d . --quiet --compact || true

# Show current state
state:
	@echo "$(GREEN)Showing Terraform state for $(ENV)...$(NC)"
	$(TF) show

# List resources in state
state-list:
	@echo "$(GREEN)Listing resources in state...$(NC)"
	$(TF) state list

# Refresh state
refresh:
	@echo "$(GREEN)Refreshing state for $(ENV)...$(NC)"
	$(TF) refresh $(ALL_VARS)

# Import existing resource
import:
	@echo "$(GREEN)Import resource...$(NC)"
	@read -p "Resource address: " addr; \
	read -p "Resource ID: " id; \
	$(TF) import $(ALL_VARS) $$addr $$id

# Show outputs
output:
	@echo "$(GREEN)Showing outputs for $(ENV)...$(NC)"
	$(TF) output

# Run all checks
all: fmt validate lint plan
	@echo "$(GREEN)All checks passed for $(ENV)!$(NC)"

# Pre-commit hooks
pre-commit:
	@echo "$(GREEN)Running pre-commit hooks...$(NC)"
	pre-commit run --all-files