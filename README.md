# OCI Infrastructure as Code with Terraform & GitHub Actions

Automated deployment of Oracle Cloud Infrastructure (OCI) resources using Terraform and GitHub Actions CI/CD pipelines.

## 📋 Quick Start

### 1. Prerequisites

- Terraform >= 1.7
- OCI CLI v2
- OCI account with API credentials
- GitHub repository access
- TFLint (optional, for linting)

### 2. OCI Setup

```bash
# Generate OCI API Key
mkdir -p ~/.oci
openssl genrsa -out ~/.oci/oci_api_key.pem 2048
openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem

# Get fingerprint
openssl rsa -pubout -outform DER -in ~/.oci/oci_api_key.pem | openssl md5 -hex

# Upload public key to OCI Console: Profile → API Keys
```

### 3. Configure GitHub Secrets

Add to repository Settings → Secrets and variables → Actions:

```
OCI_TENANCY_OCID              # Your tenancy OCID
OCI_USER_OCID                 # Your user OCID
OCI_FINGERPRINT               # API key fingerprint
OCI_API_KEY_PRIVATE           # Base64 encoded private key
OCI_REGION                    # Region (e.g., ap-singapore-1)
OCI_COMPARTMENT_OCID          # Compartment OCID
```

**Encode private key:**
```bash
base64 -w 0 ~/.oci/oci_api_key.pem | pbcopy  # macOS
base64 -w 0 ~/.oci/oci_api_key.pem | xclip   # Linux
certutil -encode oci_api_key.pem oci_api_key.b64  # Windows
```

## 📁 Repository Structure

```
.
├── .github/
│   ├── workflows/
│   │   ├── terraform-validate.yml  # Syntax & format checks
│   │   ├── terraform-plan.yml      # Plan & PR comments
│   │   ├── terraform-apply.yml     # Deploy changes
│   │   └── terraform-destroy.yml   # Manual resource cleanup
│   └── skills/                     # GitHub Copilot custom instructions
│       ├── terraform-style-guide/  # Terraform coding standards
│       └── terraform-test/         # Testing best practices
├── modules/
│   ├── apigateway/                 # API Gateway configuration
│   ├── artifact/                   # Artifact Registry
│   ├── bastion/                    # Bastion host
│   ├── container/                  # OKE cluster
│   ├── database/                   # Database services
│   ├── filestorage/                # File Storage
│   ├── logging/                    # Logging setup
│   ├── manifest/                   # Kubernetes manifests
│   ├── networking/                 # VCN, subnets, NSGs
│   ├── objstorage/                 # Object Storage
│   ├── privateendpoint/            # Private endpoints
│   ├── queue/                      # Queue service
│   ├── tag/                        # Resource tagging
│   └── vault/                      # OCI Vault (secrets)
├── tests/
│   ├── networking_unit_test.tftest.hcl   # Networking unit tests
│   └── modules/
│       └── networking_module_test.tftest.hcl
├── inputs/
│   ├── common.tfvars               # Shared variables
│   ├── dev.tfvars                  # Development environment
│   └── prod.tfvars                 # Production environment
├── docs/                           # Documentation
├── main.tf                         # Root module configuration
├── variables.tf                    # Input variables
├── outputs.tf                      # Output values
├── locals.tf                       # Local values
├── providers.tf                    # Provider configuration
├── terraform.tf                    # Terraform & provider versions
├── .tflint.hcl                     # TFLint configuration
├── Makefile                        # Common operations
└── README.md
```

## 💻 Local Development

### Initialize Terraform

```bash
# Clone repository
git clone https://github.com/khavo-25665261/oci-tf.git
cd oci-tf

# Export OCI credentials
export OCI_REGION=ap-singapore-1
export OCI_TENANCY_OCID=ocid1.tenancy.oc1...
export OCI_USER_OCID=ocid1.user.oc1...
export OCI_FINGERPRINT=aa:bb:cc:dd...
export OCI_API_KEY_FILE=~/.oci/oci_api_key.pem

# Initialize
terraform init
```

### Using Make Commands

```bash
# Show available commands
make help

# Initialize Terraform
make init

# Format and validate
make fmt
make validate

# Run linter
make lint

# Plan changes (default: dev environment)
make plan

# Plan for production
make plan ENV=prod

# Apply changes
make apply ENV=dev

# Destroy infrastructure
make destroy ENV=dev

# Run all checks (fmt, validate, lint, plan)
make all
```

### Manual Terraform Commands

```bash
# Format check
terraform fmt -check -recursive

# Validate syntax
terraform validate

# Generate plan
terraform plan -var-file="inputs/common.tfvars" -var-file="inputs/dev.tfvars" -out=tfplan

# View plan
terraform show tfplan
```

### Apply Changes

```bash
# Apply planned changes
terraform apply tfplan

# Or apply directly
terraform apply -var-file="inputs/common.tfvars" -var-file="inputs/dev.tfvars"
```

## 🧪 Testing

This project uses Terraform's native testing framework for unit and integration tests.

### Run Tests

```bash
# Run all tests
terraform test

# Run with verbose output
terraform test -verbose

# Run specific test file
terraform test tests/networking_unit_test.tftest.hcl
```

### Test Structure

Tests are organized in the `tests/` directory:

- **Unit tests** (`*_unit_test.tftest.hcl`): Fast tests using `command = plan`
- **Integration tests** (`*_integration_test.tftest.hcl`): Tests that create real resources

### Current Test Coverage

| Module | Tests | Status |
|--------|-------|--------|
| Networking | 16 tests | ✅ Passing |

## 🔍 Linting

This project uses TFLint for static analysis.

```bash
# Install TFLint (macOS)
brew install tflint

# Or download directly
curl -L "https://github.com/terraform-linters/tflint/releases/latest/download/tflint_darwin_amd64.zip" -o /tmp/tflint.zip
unzip -o /tmp/tflint.zip -d /tmp && sudo mv /tmp/tflint /usr/local/bin/

# Initialize and run
tflint --init
tflint

# Run recursively on all modules
tflint --recursive
```

### Useful Commands

```bash
# Refresh state
terraform refresh -var-file="inputs/common.tfvars" -var-file="inputs/dev.tfvars"

# Destroy all resources
terraform destroy -var-file="inputs/common.tfvars" -var-file="inputs/dev.tfvars"

# Target specific module
terraform apply -target=module.vcn -var-file="inputs/common.tfvars" -var-file="inputs/dev.tfvars"

# View outputs
terraform output

# Get specific output
terraform output vcn_ids

# State management
terraform state list
terraform state show module.vcn["main"]

# Enable debug logging
TF_LOG=DEBUG terraform plan -var-file="inputs/common.tfvars" -var-file="inputs/dev.tfvars"
```

## 📦 Modules

| Module | Description | Status |
|--------|-------------|--------|
| `networking` | VCN, subnets, route tables, NSGs | ✅ Active |
| `apigateway` | API Gateway configuration | 🔜 Planned |
| `artifact` | Artifact Registry | 🔜 Planned |
| `bastion` | Bastion host | 🔜 Planned |
| `container` | OKE (Kubernetes) cluster | 🔜 Planned |
| `database` | Database services | 🔜 Planned |
| `filestorage` | File Storage service | 🔜 Planned |
| `logging` | Logging service | 🔜 Planned |
| `manifest` | Kubernetes manifests | 🔜 Planned |
| `objstorage` | Object Storage buckets | 🔜 Planned |
| `privateendpoint` | Private endpoints | 🔜 Planned |
| `queue` | Queue service | 🔜 Planned |
| `tag` | Resource tagging | 🔜 Planned |
| `vault` | OCI Vault (secrets management) | 🔜 Planned |

## 🔧 Troubleshooting

### Authentication Issues

```bash
# Verify OCI credentials
oci os ns get

# Test API key
oci iam user get --user-id $OCI_USER_OCID

# Check GitHub secrets are set
# Settings → Secrets → Verify all secrets
```

### Plan Failures

```bash
# Enable debug logging
TF_LOG=DEBUG terraform plan -var-file="dev.tfvars"

# Validate configuration
terraform validate

# Check state
terraform state list
terraform state show [resource_name]
```

### State Lock Issues

```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

### Resource Already Exists

```bash
# Import existing resource to state
terraform import module.vcn["main"].oci_core_vcn.vcn ocid1.vcn.oc1...

# Move resource in state
terraform state mv old_resource new_resource
```

## 📚 Configuration

### Variable Files

| File | Purpose |
|------|---------|
| `inputs/common.tfvars` | Shared configuration across all environments |
| `inputs/dev.tfvars` | Development environment settings |
| `inputs/prod.tfvars` | Production environment settings |

### terraform.tf

```hcl
terraform {
  required_version = ">= 1.7"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.30"
    }
  }
}
```

### Example Variable Configuration

```hcl
# inputs/dev.tfvars
tenancy_ocid     = "ocid1.tenancy.oc1....."
compartment_ocid = "ocid1.compartment.oc1....."
region           = "ap-singapore-1"
environment      = "dev"
app_name         = "myapp"
```

## 🔗 Resources

- [Terraform OCI Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [OCI Documentation](https://docs.oracle.com/en-us/iaas/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Terraform Best Practices](https://www.terraform.io/cloud-docs/recommended-practices)
- [TFLint](https://github.com/terraform-linters/tflint)
- [Terraform Testing](https://developer.hashicorp.com/terraform/language/tests)

---

**Last Updated:** February 2026  
**Terraform Version:** >= 1.7  
**OCI Provider Version:** ~> 7.30