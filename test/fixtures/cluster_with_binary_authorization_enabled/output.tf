output "project_id" {
  value = var.project_id
}

output "source_cluster" {
  value = var.cluster
}

output "network_name" {
  value = var.network.name
}

output "subnetwork_name" {
  value = var.subnetwork.name
}

output "source_service_account" {
  value = var.service_account
}

output "cluster" {
  value = module.cluster.cluster
}

output "node_pools" {
  value = module.cluster.node_pools
}

output "service_account" {
  value = module.cluster.service_account
}