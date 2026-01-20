output "services" {
  value = data.oci_core_services.services.services
}

output "availability_domains" {
  value = data.oci_identity_availability_domains.availability_domains.availability_domains
}

output "subnets" {
  value = { for s in oci_core_subnet.subnets : s.display_name => s.id }
}

output "vcn_id" {
  value = oci_core_vcn.vcn.id
}
