output "services" {
  value = data.oci_core_services.services.services
}

output "subnets" {
  value = local.subnets
}

output "seclist" {
  value = local.seclists
}

output "nsgs" {
  value = local.nsgs
}

output "route_tables" {
  value = local.route_tables
}

output "vcn_id" {
  value = oci_core_vcn.vcn.id
}
