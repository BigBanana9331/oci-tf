# GitHub Actions Workflows

This directory contains CI/CD workflows for automated Terraform infrastructure management.

## 📑 Table of Contents

- [Workflow Overview](#workflow-overview)
- [Workflow Diagrams](#workflow-diagrams)
- [Workflows](#workflows)
  - [terraform-validate.yml](#terraform-validateyml)
  - [terraform-plan.yml](#terraform-planyml)
  - [terraform-apply.yml](#terraform-applyyml)
  - [terraform-destroy.yml](#terraform-destroyyml)
- [Required Secrets](#required-secrets)
- [Required Variables](#required-variables)
- [Environment Setup](#environment-setup)
- [Usage Examples](#usage-examples)

---

## Workflow Overview

| Workflow | Trigger | Purpose | Environments |
|----------|---------|---------|--------------|
| `terraform-validate` | Push to `main` | Format, validate, lint, security scan | N/A |
| `terraform-plan` | PR to `main` / Manual | Preview infrastructure changes | dev, prod |
| `terraform-apply` | Manual | Deploy infrastructure changes | dev, prod |
| `terraform-destroy` | Manual (protected) | Tear down infrastructure | dev, prod |

---

## Workflow Diagrams

### CI/CD Pipeline Flow

```mermaid
flowchart LR
    subgraph Validate["🔍 Validate (Auto)"]
        Push[Push to main] --> Format[terraform fmt]
        Format --> Val[terraform validate]
        Val --> TFLint[TFLint]
        TFLint --> Trivy[Trivy Scan]
    end

    subgraph Plan["📋 Plan"]
        PR[Pull Request] --> PlanDev[Plan Dev]
        PR --> PlanProd[Plan Prod]
        PlanDev --> Comment[PR Comment]
        PlanProd --> Comment
    end

    subgraph Apply["🚀 Apply (Manual)"]
        Trigger[Manual Trigger] --> APlanDev[Plan Dev]
        Trigger --> APlanProd[Plan Prod]
        APlanDev --> ApplyDev[Apply Dev]
        APlanProd --> ApplyProd[Apply Prod]
    end

    Validate -.-> Plan
    Plan -.-> Apply
```

### Destroy Protection Flow

```mermaid
flowchart TB
    Start[🔴 Destroy Triggered] --> Input{Environment?}
    
    Input -->|dev| ValidateDev[Validate<br/>destroy-dev]
    Input -->|prod| ValidateProd[Validate<br/>destroy-prod]
    
    ValidateDev -->|✅ Pass| DestroyDev[Destroy Dev]
    ValidateDev -->|❌ Fail| CancelDev[Cancelled]
    
    ValidateProd -->|✅ Pass| ProdGate[🛡️ prod-destroy<br/>Environment Approval]
    ValidateProd -->|❌ Fail| CancelProd[Cancelled]
    
    ProdGate -->|Approved| Wait[⏱️ 30s Delay]
    ProdGate -->|Rejected| CancelProd
    
    Wait --> DestroyProd[Destroy Prod]
    
    DestroyDev --> Done[✅ Complete]
    DestroyProd --> Done
```

---

## Workflows

### terraform-validate.yml

**Purpose:** Validates Terraform code quality and security on every push.

**Trigger:**
- Push to `main` branch (specific paths: `*.tf`, `modules/**`, `inputs/**`)

**Jobs:**

| Job | Steps | Description |
|-----|-------|-------------|
| `validate` | Format Check | `terraform fmt -check -recursive` |
| | Init | `terraform init -backend=false` |
| | Validate | `terraform validate` |
| | TFLint | Lints all modules recursively |
| `trivy-scan` | Security Scan | Scans for HIGH/CRITICAL vulnerabilities |
| | Upload SARIF | Results appear in Security tab |

**No inputs required** - runs automatically.

---

### terraform-plan.yml

**Purpose:** Creates execution plans for infrastructure changes.

**Triggers:**
- Pull Request to `main` (auto-runs for both dev & prod)
- Manual dispatch (choose environment)

**Inputs:**

| Input | Type | Required | Default | Options |
|-------|------|----------|---------|---------|
| `environment` | choice | Yes | `all` | `all`, `dev`, `prod` |

**Features:**
- Posts plan output as PR comment
- Plans saved for apply workflow
- Uses backend state for accurate diffs

**Example PR Comment:**
```
### Terraform Plan: `dev` 📋

```hcl
Terraform will perform the following actions:

  # module.vcn["vcn-0"].oci_core_vcn.vcn will be created
  + resource "oci_core_vcn" "vcn" { ... }

Plan: 5 to add, 0 to change, 0 to destroy.
```

*Triggered by @username on `pull_request`*
```

---

### terraform-apply.yml

**Purpose:** Deploys infrastructure changes to OCI.

**Trigger:** Manual dispatch only (`workflow_dispatch`)

**Jobs:**

| Job | Description |
|-----|-------------|
| `plan` | Creates plan for each environment in matrix |
| `apply` | Applies the cached plan (requires environment approval) |

**Features:**
- Matrix strategy for parallel dev/prod
- Plans cached between jobs
- Environment protection gates
- Backend state management

**State File Path:**
```
statefile/{region}/{app_name}/{environment}.tfstate

Example:
statefile/ap-singapore-1/helloapp/dev.tfstate
statefile/ap-singapore-1/helloapp/prod.tfstate
```

---

### terraform-destroy.yml

**Purpose:** Safely tears down infrastructure with multiple protection layers.

**Trigger:** Manual dispatch only (`workflow_dispatch`)

**Inputs:**

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `environment` | choice | ✅ | `dev` or `prod` |
| `confirm` | string | ✅ | Must type `destroy-dev` or `destroy-prod` |
| `reason` | string | ✅ | Audit trail for destruction |
| `ticket` | string | ❌ | Optional ticket/issue reference |

**Protection Layers:**

| Layer | Dev | Prod | Description |
|-------|-----|------|-------------|
| 1. Confirmation word | ✅ | ✅ | Must match `destroy-{env}` |
| 2. Reason required | ✅ | ✅ | Mandatory audit trail |
| 3. Environment approval | ✅ | ✅ | Standard environment gate |
| 4. `prod-destroy` approval | ❌ | ✅ | Extra approval for prod |
| 5. 30-second delay | ❌ | ✅ | Cooling off period |
| 6. Plan before destroy | ✅ | ✅ | Shows what will be deleted |

---

## Required Secrets

Configure in **Settings → Secrets and variables → Actions → Secrets**:

| Secret | Description | Example |
|--------|-------------|---------|
| `OCI_CONFIG_FILE` | Full OCI config file content | `[DEFAULT]\nuser=ocid1...` |
| `OCI_KEY_FILE` | OCI API private key (PEM format) | `-----BEGIN RSA PRIVATE KEY-----...` |
| `OCI_TENANCY_OCID` | Tenancy OCID | `ocid1.tenancy.oc1..aaa...` |
| `OCI_REGION` | OCI Region | `ap-singapore-1` |
| `TF_VAR_COMPARTMENT_OCID` | Compartment OCID | `ocid1.compartment.oc1..aaa...` |
| `BACKEND_CONFIG_BUCKET` | State bucket name | `terraform-state` |
| `BACKEND_CONFIG_NAMESPACE` | OCI namespace | `mytenancy` |

---

## Required Variables

Configure in **Settings → Secrets and variables → Actions → Variables**:

| Variable | Description | Example |
|----------|-------------|---------|
| `APP_NAME` | Application name for resource naming | `helloapp` |

---

## Environment Setup

### Create Environments

Go to **Settings → Environments** and create:

#### 1. `dev`
- No special protection (optional reviewers)

#### 2. `prod`
- ✅ Required reviewers: Add 1-2 approvers
- 🔒 Deployment branches: `main` only

#### 3. `prod-destroy` (Critical!)
- ✅ Required reviewers: Add 2+ senior approvers
- ⏱️ Wait timer: 5 minutes (recommended)
- 🔒 Deployment branches: `main` only

---

## Usage Examples

### 1. Validate Code (Automatic)
```bash
# Just push to main - workflow runs automatically
git push origin main
```

### 2. Plan Changes (PR)
```bash
# Create a PR - plans run automatically for both environments
git checkout -b feature/add-subnet
# ... make changes ...
git push origin feature/add-subnet
# Create PR → Plans appear as comments
```

### 3. Plan Changes (Manual)
```yaml
# Go to Actions → Terraform Plan → Run workflow
Environment: dev  # or 'all' for both
```

### 4. Apply Changes
```yaml
# Go to Actions → Terraform Apply → Run workflow
# Runs for both dev and prod with environment approvals
```

### 5. Destroy Dev Environment
```yaml
# Go to Actions → Terraform Destroy → Run workflow
Environment: dev
Confirm: destroy-dev
Reason: Cleanup after testing sprint 23
Ticket: JIRA-456
```

### 6. Destroy Prod Environment (Multi-approval)
```yaml
# Go to Actions → Terraform Destroy → Run workflow
Environment: prod
Confirm: destroy-prod
Reason: Decommissioning legacy infrastructure
Ticket: CHG-789

# After submit:
# 1. Validation job runs
# 2. Requires approval from prod-destroy environment reviewers
# 3. 30-second wait after approval
# 4. Destruction proceeds
```

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "Confirmation failed" on destroy | Type exactly `destroy-dev` or `destroy-prod` |
| Plan not appearing on PR | Check PR is targeting `main` branch |
| Apply fails with state lock | Check for concurrent runs, use `terraform force-unlock` |
| Trivy scan failing | Review security findings in Security tab |

### Debug Mode

Add to any workflow step for verbose output:
```yaml
env:
  TF_LOG: DEBUG
```

---

## Security Best Practices

1. **Never commit secrets** - Use GitHub Secrets only
2. **Require PR reviews** - Don't merge without code review
3. **Use environment protection** - Especially for `prod` and `prod-destroy`
4. **Audit destroy operations** - Review reason and ticket fields
5. **Limit workflow permissions** - Use minimum required permissions
6. **Rotate API keys regularly** - See Runbook RB-12

---

**Last Updated:** February 2026
