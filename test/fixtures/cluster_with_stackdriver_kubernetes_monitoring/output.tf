output "project_id" {
  value = var.project_id
}

output "cluster_name" {
  value = module.cluster.cluster_name
}

output "location" {
  value = module.cluster.location
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