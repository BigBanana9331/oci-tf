# =============================================================================
# Networking Module Tests (Plan Mode)
# =============================================================================
# Tests specifically for the networking module
# Run with: terraform test tests/modules/networking_module_test.tftest.hcl

# -----------------------------------------------------------------------------
# Mock Provider for OCI
# -----------------------------------------------------------------------------
mock_provider "oci" {
  mock_resource "oci_core_vcn" {
    defaults = {
      id             = "ocid1.vcn.oc1.ap-singapore-1.test123"
      cidr_blocks    = ["10.0.0.0/16"]
      compartment_id = "ocid1.compartment.oc1..test"
      display_name   = "test-vcn"
      state          = "AVAILABLE"
    }
  }

  mock_resource "oci_core_service_gateway" {
    defaults = {
      id             = "ocid1.servicegateway.oc1.ap-singapore-1.test123"
      compartment_id = "ocid1.compartment.oc1..test"
      display_name   = "test-sg"
      state          = "AVAILABLE"
      vcn_id         = "ocid1.vcn.oc1.ap-singapore-1.test123"
    }
  }

  mock_resource "oci_core_nat_gateway" {
    defaults = {
      id             = "ocid1.natgateway.oc1.ap-singapore-1.test123"
      compartment_id = "ocid1.compartment.oc1..test"
      display_name   = "test-natgw"
      state          = "AVAILABLE"
      vcn_id         = "ocid1.vcn.oc1.ap-singapore-1.test123"
      nat_ip         = "129.146.0.1"
    }
  }

  mock_resource "oci_core_subnet" {
    defaults = {
      id                         = "ocid1.subnet.oc1.ap-singapore-1.test123"
      compartment_id             = "ocid1.compartment.oc1..test"
      cidr_block                 = "10.0.1.0/24"
      display_name               = "test-subnet"
      state                      = "AVAILABLE"
      vcn_id                     = "ocid1.vcn.oc1.ap-singapore-1.test123"
      prohibit_public_ip_on_vnic = true
    }
  }

  mock_resource "oci_core_route_table" {
    defaults = {
      id             = "ocid1.routetable.oc1.ap-singapore-1.test123"
      compartment_id = "ocid1.compartment.oc1..test"
      display_name   = "test-rt"
      state          = "AVAILABLE"
      vcn_id         = "ocid1.vcn.oc1.ap-singapore-1.test123"
    }
  }

  mock_resource "oci_core_network_security_group" {
    defaults = {
      id             = "ocid1.nsg.oc1.ap-singapore-1.test123"
      compartment_id = "ocid1.compartment.oc1..test"
      display_name   = "test-nsg"
      state          = "AVAILABLE"
      vcn_id         = "ocid1.vcn.oc1.ap-singapore-1.test123"
    }
  }

  mock_resource "oci_core_network_security_group_security_rule" {
    defaults = {
      id                        = "test-rule-id"
      network_security_group_id = "ocid1.nsg.oc1.ap-singapore-1.test123"
      direction                 = "EGRESS"
      protocol                  = "6"
    }
  }

  mock_data "oci_core_services" {
    defaults = {
      services = [
        {
          id         = "ocid1.service.oc1.ap-singapore-1.test"
          name       = "All SIN Services In Oracle Services Network"
          cidr_block = "all-sin-services-in-oracle-services-network"
        }
      ]
    }
  }
}

# =============================================================================
# Test: Networking Module with Default Values
# =============================================================================
run "test_networking_module_defaults" {
  command = plan

  module {
    source = "./modules/networking"
  }

  variables {
    environment    = "dev"
    app_name       = "testapp"
    compartment_id = "ocid1.compartment.oc1..test"
    vcn_name       = "vcn-0"
    cidr_blocks    = ["10.0.0.0/16"]
    tags = {
      definedTags  = {}
      freeformTags = { "CreatedBy" = "Terraform" }
    }
    route_tables = {
      "routetable-private" = [
        {
          network_entity_name = "svcgw"
          destination         = "all-sin-services-in-oracle-services-network"
          destination_type    = "SERVICE_CIDR_BLOCK"
          description         = "Service gateway route"
        }
      ]
    }
    subnets = {
      "subnet-test" = {
        cidr_block       = "10.0.1.0/24"
        route_table_name = "routetable-private"
      }
    }
    nsgs = {}
  }

  assert {
    condition     = oci_core_vcn.vcn.cidr_blocks[0] == "10.0.0.0/16"
    error_message = "VCN should have correct CIDR block"
  }

  assert {
    condition     = oci_core_vcn.vcn.display_name == "dev-testapp-vcn-0"
    error_message = "VCN display name should follow naming convention"
  }
}

# =============================================================================
# Test: VCN Naming Convention
# =============================================================================
run "test_vcn_naming_convention" {
  command = plan

  module {
    source = "./modules/networking"
  }

  variables {
    environment    = "prod"
    app_name       = "myapp"
    compartment_id = "ocid1.compartment.oc1..test"
    vcn_name       = "main"
    cidr_blocks    = ["172.16.0.0/16"]
    tags = {
      definedTags  = {}
      freeformTags = {}
    }
    route_tables = {}
    subnets      = {}
    nsgs         = {}
  }

  assert {
    condition     = oci_core_vcn.vcn.display_name == "prod-myapp-main"
    error_message = "VCN name should be 'prod-myapp-main'"
  }
}

# =============================================================================
# Test: Multiple Subnets Creation
# =============================================================================
run "test_multiple_subnets" {
  command = plan

  module {
    source = "./modules/networking"
  }

  variables {
    environment    = "dev"
    app_name       = "testapp"
    compartment_id = "ocid1.compartment.oc1..test"
    vcn_name       = "vcn-0"
    cidr_blocks    = ["10.0.0.0/16"]
    tags = {
      definedTags  = {}
      freeformTags = {}
    }
    route_tables = {
      "rt-private" = [
        {
          network_entity_name = "natgw"
          destination         = "0.0.0.0/0"
          destination_type    = "CIDR_BLOCK"
          description         = "NAT gateway route"
        }
      ]
    }
    subnets = {
      "subnet-api" = {
        cidr_block       = "10.0.1.0/24"
        route_table_name = "rt-private"
      }
      "subnet-worker" = {
        cidr_block       = "10.0.2.0/24"
        route_table_name = "rt-private"
      }
      "subnet-db" = {
        cidr_block       = "10.0.3.0/24"
        route_table_name = "rt-private"
      }
    }
    nsgs = {}
  }

  assert {
    condition     = length(oci_core_subnet.subnets) == 3
    error_message = "Should create 3 subnets"
  }
}

# =============================================================================
# Test: NSG Rules Creation
# =============================================================================
run "test_nsg_rules_creation" {
  command = plan

  module {
    source = "./modules/networking"
  }

  variables {
    environment    = "dev"
    app_name       = "testapp"
    compartment_id = "ocid1.compartment.oc1..test"
    vcn_name       = "vcn-0"
    cidr_blocks    = ["10.0.0.0/16"]
    tags = {
      definedTags  = {}
      freeformTags = {}
    }
    route_tables = {}
    subnets      = {}
    nsgs = {
      "nsg-web" = [
        {
          direction   = "INGRESS"
          protocol    = "6"
          source_type = "CIDR_BLOCK"
          source      = "0.0.0.0/0"
          description = "Allow HTTPS from internet"
          tcp_options = {
            destination_port_range = {
              min = 443
              max = 443
            }
          }
        },
        {
          direction        = "EGRESS"
          protocol         = "all"
          destination_type = "CIDR_BLOCK"
          destination      = "0.0.0.0/0"
          description      = "Allow all outbound"
        }
      ]
    }
  }

  assert {
    condition     = length(oci_core_network_security_group.network_security_groups) == 1
    error_message = "Should create 1 NSG"
  }
}

# =============================================================================
# Test: Service Gateway Creation
# =============================================================================
run "test_service_gateway_creation" {
  command = plan

  module {
    source = "./modules/networking"
  }

  variables {
    environment          = "dev"
    app_name             = "testapp"
    compartment_id       = "ocid1.compartment.oc1..test"
    vcn_name             = "vcn-0"
    cidr_blocks          = ["10.0.0.0/16"]
    service_gateway_name = "svcgw"
    nat_gateway_name     = "natgw"
    tags = {
      definedTags  = {}
      freeformTags = {}
    }
    route_tables = {}
    subnets      = {}
    nsgs         = {}
  }

  assert {
    condition     = length(oci_core_service_gateway.service_gateway) == 1
    error_message = "Service gateway should be created"
  }

  assert {
    condition     = length(oci_core_nat_gateway.nat_gateway) == 1
    error_message = "NAT gateway should be created"
  }
}

# =============================================================================
# Test: No Gateways When Disabled
# =============================================================================
run "test_no_gateways_when_disabled" {
  command = plan

  module {
    source = "./modules/networking"
  }

  variables {
    environment          = "dev"
    app_name             = "testapp"
    compartment_id       = "ocid1.compartment.oc1..test"
    vcn_name             = "vcn-0"
    cidr_blocks          = ["10.0.0.0/16"]
    service_gateway_name = null
    nat_gateway_name     = null
    tags = {
      definedTags  = {}
      freeformTags = {}
    }
    route_tables = {}
    subnets      = {}
    nsgs         = {}
  }

  assert {
    condition     = length(oci_core_service_gateway.service_gateway) == 0
    error_message = "Service gateway should not be created when disabled"
  }

  assert {
    condition     = length(oci_core_nat_gateway.nat_gateway) == 0
    error_message = "NAT gateway should not be created when disabled"
  }
}

# =============================================================================
# Test: Outputs Exist
# =============================================================================
run "test_module_outputs" {
  command = plan

  module {
    source = "./modules/networking"
  }

  variables {
    environment    = "dev"
    app_name       = "testapp"
    compartment_id = "ocid1.compartment.oc1..test"
    vcn_name       = "vcn-0"
    cidr_blocks    = ["10.0.0.0/16"]
    tags = {
      definedTags  = {}
      freeformTags = {}
    }
    route_tables = {}
    subnets      = {}
    nsgs         = {}
  }

  assert {
    condition     = output.vcn_id != ""
    error_message = "VCN ID output should not be empty"
  }

  assert {
    condition     = output.services != null
    error_message = "Services output should exist"
  }
}

# =============================================================================
# Test: Tags Applied Correctly
# =============================================================================
run "test_tags_applied" {
  command = plan

  module {
    source = "./modules/networking"
  }

  variables {
    environment    = "dev"
    app_name       = "testapp"
    compartment_id = "ocid1.compartment.oc1..test"
    vcn_name       = "vcn-0"
    cidr_blocks    = ["10.0.0.0/16"]
    tags = {
      definedTags = {
        "Operations.CostCenter" = "42"
      }
      freeformTags = {
        "CreatedBy"   = "Terraform"
        "Environment" = "Development"
      }
    }
    route_tables = {}
    subnets      = {}
    nsgs         = {}
  }

  assert {
    condition     = oci_core_vcn.vcn.freeform_tags["CreatedBy"] == "Terraform"
    error_message = "VCN should have CreatedBy freeform tag"
  }
}
