# OCI Infrastructure as Code with Terraform & GitHub Actions

Automated deployment of Oracle Cloud Infrastructure (OCI) resources using Terraform and GitHub Actions CI/CD pipelines.

## 📋 Quick Start

### 1. Prerequisites

- Terraform >= 1.5.7
- OCI CLI v2
- OCI account with API credentials
- GitHub repository access

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
├── .github/workflows/
│   ├── terraform-validate.yml      # Syntax & format checks
│   ├── terraform-plan.yml          # Plan & PR comments
│   ├── terraform-apply.yml         # Deploy changes
│   ├── terraform-security.yml      # Trivy vulnerability scan
│   └── terraform-destroy.yml       # Manual resource cleanup
├── modules/
│   ├── networking/                 # VCN, subnets, NSGs
│   ├── container/                  # OKE cluster
│   ├── logging/                    # Logging setup
│   ├── bastion/                    # Bastion host
│   └── [other modules]/
├── main.tf                         # Root module configuration
├── variables.tf                    # Input variables
├── outputs.tf                      # Output values
├── terraform.tf                    # Provider & versions
├── dev.tfvars                      # Development variables
├── .gitignore                      # Git ignore rules
└── README.md
```

## 💻 Local Development

### Initialize Terraform

```bash
# Clone repository
git clone https://github.com/BigBanana9331/oci-oke-tf.git
cd oci-terraform

# Export OCI credentials
export OCI_REGION=ap-singapore-1
export OCI_TENANCY_OCID=ocid1.tenancy.oc1...
export OCI_USER_OCID=ocid1.user.oc1...
export OCI_FINGERPRINT=aa:bb:cc:dd...
export OCI_API_KEY_FILE=~/.oci/oci_api_key.pem

# Initialize
terraform init
```

### Plan Changes

```bash
# Format check
terraform fmt -check -recursive

# Validate syntax
terraform validate

# Generate plan
terraform plan -var-file="dev.tfvars" -out=tfplan

# View plan
terraform show tfplan
```

### Apply Changes

```bash
# Apply planned changes
terraform apply tfplan

# Or apply directly
terraform apply -var-file="dev.tfvars"
```

### Useful Commands

```bash
# Refresh state
terraform refresh -var-file="dev.tfvars"

# Destroy all resources
terraform destroy -var-file="dev.tfvars"

# Target specific resource
terraform apply -target=oci_core_vcn.vcn -var-file="dev.tfvars"

# View outputs
terraform output

# Get specific output
terraform output cluster_id

# State management
terraform state list
terraform state show oci_core_vcn.vcn

# Enable debug logging
TF_LOG=DEBUG terraform plan -var-file="dev.tfvars"
```

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
terraform force-unlock LOCK_ID -var-file="dev.tfvars"
```

### Resource Already Exists

```bash
# Import existing resource to state
terraform import oci_core_vcn.vcn ocid1.vcn.oc1...

# Move resource in state
terraform state mv old_resource new_resource
```

## 📚 Configuration Files

### variables.tf

```hcl
terraform {
  required_version = ">= 1.5.7"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.30"
    }
  }
}

variable "compartment_ocid" {
  type        = string
  description = "The OCID of the OCI compartment"
}

variable "region" {
  type        = string
  description = "OCI region"
}

variable "tenancy_ocid" {
  type        = string
  description = "The OCID of the OCI tenancy"
}
```

### dev.tfvars

```hcl
tenancy_ocid     = "ocid1.tenancy.oc1....."
compartment_ocid = "ocid1.compartment.oc1....."
region           = "ap-singapore-1"
```

## 🔗 Resources

- [Terraform OCI Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [OCI Documentation](https://docs.oracle.com/en-us/iaas/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Terraform Best Practices](https://www.terraform.io/cloud-docs/recommended-practices)

---

**Last Updated:** January 2026  
**Terraform Version:** >= 1.5.7  
**OCI Provider Version:** ~> 7.30