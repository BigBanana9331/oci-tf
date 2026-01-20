output "services" {
  value = data.oci_core_services.services.services
}

output "availability_domains" {
  value = data.oci_identity_availability_domains.availability_domains.availability_domains
}