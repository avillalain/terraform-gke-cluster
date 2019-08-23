output "project"{
  value = var.project
}

output "cluster" {
  value = local.cluster
}

output "node_pools" {
  value = local.node_pools
}

output "service_account" {
  value = local.service_account
}