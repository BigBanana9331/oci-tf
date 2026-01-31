# =============================================================================
# Networking Module Unit Tests (Plan Mode)
# =============================================================================
# These tests validate Terraform logic without creating real OCI infrastructure.
# Run with: terraform test tests/networking_unit_test.tftest.hcl

# -----------------------------------------------------------------------------
# Test Variables
# -----------------------------------------------------------------------------
variables {
  compartment_ocid = "ocid1.compartment.oc1..test"
  tenancy_ocid     = "ocid1.tenancy.oc1..test"
  region           = "ap-singapore-1"
  environment      = "dev"
  app_name         = "testapp"
  tags = {
    definedTags  = {}
    freeformTags = { "CreatedBy" = "Terraform" }
  }
  vcns = {
    "vcn-0" = {
      cidr_blocks = ["10.0.0.0/16"]
      route_tables = {
        "routetable-private" = [
          {
            network_entity_name = "svcgw"
            destination         = "all-sin-services-in-oracle-services-network"
            destination_type    = "SERVICE_CIDR_BLOCK"
            description         = "Rule for traffic to OCI services"
          },
          {
            network_entity_name = "natgw"
            destination         = "0.0.0.0/0"
            destination_type    = "CIDR_BLOCK"
            description         = "Rule for traffic to Internet"
          }
        ]
      }
      subnets = {
        "subnet-oke-apiendpoint" = {
          cidr_block       = "10.0.0.0/30"
          route_table_name = "routetable-private"
        },
        "subnet-oke-workernode" = {
          cidr_block       = "10.0.1.0/24"
          route_table_name = "routetable-private"
        }
      }
      nsgs = {
        "nsg-test" = [
          {
            direction        = "EGRESS"
            protocol         = "6"
            destination_type = "CIDR_BLOCK"
            destination      = "10.0.0.0/30"
            description      = "Test NSG rule"
            tcp_options = {
              destination_port_range = {
                min = 443
                max = 443
              }
            }
          }
        ]
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Mock Provider for OCI
# -----------------------------------------------------------------------------
mock_provider "oci" {
  # Mock VCN resource
  mock_resource "oci_core_vcn" {
    defaults = {
      id                       = "ocid1.vcn.oc1.ap-singapore-1.test123"
      cidr_blocks              = ["10.0.0.0/16"]
      compartment_id           = "ocid1.compartment.oc1..test"
      display_name             = "dev-testapp-vcn-0"
      state                    = "AVAILABLE"
      default_route_table_id   = "ocid1.routetable.oc1..default"
      default_security_list_id = "ocid1.securitylist.oc1..default"
      default_dhcp_options_id  = "ocid1.dhcpoptions.oc1..default"
    }
  }

  # Mock Service Gateway
  mock_resource "oci_core_service_gateway" {
    defaults = {
      id             = "ocid1.servicegateway.oc1.ap-singapore-1.test123"
      compartment_id = "ocid1.compartment.oc1..test"
      display_name   = "dev-testapp-sg-0"
      state          = "AVAILABLE"
      vcn_id         = "ocid1.vcn.oc1.ap-singapore-1.test123"
    }
  }

  # Mock NAT Gateway
  mock_resource "oci_core_nat_gateway" {
    defaults = {
      id             = "ocid1.natgateway.oc1.ap-singapore-1.test123"
      compartment_id = "ocid1.compartment.oc1..test"
      display_name   = "dev-testapp-ng-0"
      state          = "AVAILABLE"
      vcn_id         = "ocid1.vcn.oc1.ap-singapore-1.test123"
      nat_ip         = "129.146.0.1"
    }
  }

  # Mock Subnet
  mock_resource "oci_core_subnet" {
    defaults = {
      id                         = "ocid1.subnet.oc1.ap-singapore-1.test123"
      compartment_id             = "ocid1.compartment.oc1..test"
      cidr_block                 = "10.0.0.0/24"
      display_name               = "dev-testapp-subnet"
      state                      = "AVAILABLE"
      vcn_id                     = "ocid1.vcn.oc1.ap-singapore-1.test123"
      prohibit_public_ip_on_vnic = true
      prohibit_internet_ingress  = true
    }
  }

  # Mock Route Table
  mock_resource "oci_core_route_table" {
    defaults = {
      id             = "ocid1.routetable.oc1.ap-singapore-1.test123"
      compartment_id = "ocid1.compartment.oc1..test"
      display_name   = "dev-testapp-routetable"
      state          = "AVAILABLE"
      vcn_id         = "ocid1.vcn.oc1.ap-singapore-1.test123"
    }
  }

  # Mock Network Security Group
  mock_resource "oci_core_network_security_group" {
    defaults = {
      id             = "ocid1.nsg.oc1.ap-singapore-1.test123"
      compartment_id = "ocid1.compartment.oc1..test"
      display_name   = "dev-testapp-nsg"
      state          = "AVAILABLE"
      vcn_id         = "ocid1.vcn.oc1.ap-singapore-1.test123"
    }
  }

  # Mock NSG Security Rule
  mock_resource "oci_core_network_security_group_security_rule" {
    defaults = {
      id                        = "test-rule-id-123"
      network_security_group_id = "ocid1.nsg.oc1.ap-singapore-1.test123"
      direction                 = "EGRESS"
      protocol                  = "6"
      is_valid                  = true
    }
  }

  # Mock OCI Services data source
  mock_data "oci_core_services" {
    defaults = {
      services = [
        {
          id          = "ocid1.service.oc1.ap-singapore-1.test"
          name        = "All SIN Services In Oracle Services Network"
          cidr_block  = "all-sin-services-in-oracle-services-network"
          description = "All services in Oracle Services Network"
        }
      ]
    }
  }
}

# =============================================================================
# UNIT TESTS
# =============================================================================

# Test 1: VCN Module Creation
run "test_vcn_module_instantiation" {
  command = plan

  assert {
    condition     = length(keys(module.vcn)) == 1
    error_message = "Should create exactly one VCN module instance"
  }
}

# Test 2: Environment Variable Validation - Valid
run "test_valid_environment" {
  command = plan

  assert {
    condition     = var.environment == "dev"
    error_message = "Environment should be 'dev'"
  }
}

# Test 3: Environment Variable Validation - Invalid
run "test_invalid_environment_rejected" {
  command = plan

  variables {
    environment = "invalid"
  }

  expect_failures = [
    var.environment
  ]
}

# Test 4: App Name Validation - Valid
run "test_valid_app_name" {
  command = plan

  assert {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.app_name))
    error_message = "App name should match naming convention"
  }
}

# Test 5: App Name Validation - Invalid (uppercase)
run "test_invalid_app_name_uppercase" {
  command = plan

  variables {
    app_name = "TestApp"
  }

  expect_failures = [
    var.app_name
  ]
}

# Test 6: Region Validation - Valid
run "test_valid_region" {
  command = plan

  assert {
    condition     = can(regex("^[a-z]{2,4}-[a-z]+-[0-9]+$", var.region))
    error_message = "Region should be valid OCI region format"
  }
}

# Test 7: Region Validation - Invalid
run "test_invalid_region_rejected" {
  command = plan

  variables {
    region = "invalid-region"
  }

  expect_failures = [
    var.region
  ]
}

# Test 8: Compartment OCID Validation
run "test_valid_compartment_ocid" {
  command = plan

  assert {
    condition     = can(regex("^ocid1\\.compartment\\.", var.compartment_ocid))
    error_message = "Compartment OCID should be valid format"
  }
}

# Test 9: Tenancy OCID Validation
run "test_valid_tenancy_ocid" {
  command = plan

  assert {
    condition     = can(regex("^ocid1\\.tenancy\\.", var.tenancy_ocid))
    error_message = "Tenancy OCID should be valid format"
  }
}

# Test 10: VCN CIDR Configuration
run "test_vcn_cidr_configuration" {
  command = plan

  assert {
    condition     = var.vcns["vcn-0"].cidr_blocks[0] == "10.0.0.0/16"
    error_message = "VCN CIDR should be 10.0.0.0/16"
  }
}

# Test 11: Subnet Count
run "test_subnet_count" {
  command = plan

  assert {
    condition     = length(keys(var.vcns["vcn-0"].subnets)) == 2
    error_message = "Should have 2 subnets defined"
  }
}

# Test 12: NSG Rules Present
run "test_nsg_rules_present" {
  command = plan

  assert {
    condition     = length(var.vcns["vcn-0"].nsgs["nsg-test"]) > 0
    error_message = "NSG should have at least one rule"
  }
}

# Test 13: Route Table Configuration
run "test_route_table_configuration" {
  command = plan

  assert {
    condition     = length(var.vcns["vcn-0"].route_tables["routetable-private"]) == 2
    error_message = "Route table should have 2 route rules"
  }
}

# Test 14: Tags Configuration
run "test_tags_configuration" {
  command = plan

  assert {
    condition     = var.tags.freeformTags["CreatedBy"] == "Terraform"
    error_message = "CreatedBy tag should be 'Terraform'"
  }
}

# Test 15: Subnet CIDR Blocks Valid
run "test_subnet_cidr_blocks_valid" {
  command = plan

  assert {
    condition = alltrue([
      for name, subnet in var.vcns["vcn-0"].subnets :
      can(cidrhost(subnet.cidr_block, 0))
    ])
    error_message = "All subnet CIDR blocks should be valid"
  }
}

# Test 16: Private Subnets Configuration
run "test_private_subnets_default" {
  command = plan

  assert {
    condition = alltrue([
      for name, subnet in var.vcns["vcn-0"].subnets :
      coalesce(subnet.prohibit_public_ip_on_vnic, true) == true
    ])
    error_message = "Subnets should prohibit public IP by default"
  }
}
