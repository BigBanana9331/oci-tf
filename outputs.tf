output "keys" {
  value = local.keys
}

output "subnets" {
  value = local.subnets
}

output "nsgs" {
  value = local.nsgs
}

output "options" {
  value = data.oci_containerengine_node_pool_option.node_pool_option
}