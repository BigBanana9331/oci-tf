terraform {
  required_version = ">= 1.5.7"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.30"
    }
  }
  backend "oci" {}
}

provider "oci" {
  config_file_profile = "DEFAULT"
}