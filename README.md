# OCI Terraform

## Require
- Terraform repository for Stack
- OCI account (admin role required)

## Guideline
### Configuration source providers
#### Docs
-  https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/terraformconfigresourcemanager.htm
- https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Concepts/resourcemanager.htm#concepts__stackdefinition
#### Steps
1. Set the source providers
2. Add the description (optional)
3. Choose compartment for the stack to be created.
4. Choose Access Type: Public for Repo accessible for Internet/ Private for repo hosted privately
5. Choose and config the source repo

![image](./docs/assets/source_provider.png)

### Create Stacks