terraform {
  required_version = ">= 1.5.7"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
  }
}



variable "compartment_id" {
  type = string
}

variable "subnet_id" {
  type = string
}
