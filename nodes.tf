resource "google_container_node_pool" "node_pools" {
  provider = google-beta
  count    = length(var.node_pools)
  cluster  = google_container_cluster.cluster.name
  project  = var.project
  location = var.cluster.location
  autoscaling {
    min_node_count = var.node_pools[count.index].min_nodes
    max_node_count = var.node_pools[count.index].max_nodes
  }
  initial_node_count = var.node_pools[count.index].min_nodes
  management {
    auto_repair  = true
    auto_upgrade = true
  }
  max_pods_per_node = var.node_pools[count.index].max_pods_per_node
  name              = var.node_pools[count.index].name
  node_config {
    disk_size_gb = var.node_pools[count.index].disk_size_gb
    disk_type    = var.node_pools[count.index].disk_type
    labels = merge(
      local.node_pool_base_label,
      { "node_pool" = var.node_pools[count.index].name },
      var.node_pools[count.index].labels
    )
    local_ssd_count = var.node_pools[count.index].ssd_count
    machine_type    = var.node_pools[count.index].machine_type
    metadata = merge(
      local.node_pool_base_metadata,
      { "node_pool" = var.node_pools[count.index].name },
      var.node_pools[count.index].metadata
    )
    min_cpu_platform = var.node_pools[count.index].min_cpu_platform
    preemptible      = var.node_pools[count.index].preemptible
    service_account  = google_service_account.service_account.email
    tags = concat(
      local.node_pool_base_tags,
      ["gke-${google_container_cluster.cluster.name}-${var.node_pools[count.index].name}"],
      var.node_pools[count.index].tags
    )
    dynamic "taint" {
      for_each = [for taint in var.node_pools[count.index].taints : {
        effect = taint.effect
        key    = taint.key
        value  = taint.value
      }]
      content {
        effect = taint.value.effect
        key    = taint.value.key
        value  = taint.value.value
      }
    }
  }
}

locals {
  node_pools = [for node_pool in google_container_node_pool.node_pools : {
    min_nodes         = node_pool.autoscaling[0].min_node_count
    max_nodes         = node_pool.autoscaling[0].max_node_count
    max_pods_per_node = node_pool.max_pods_per_node
    name              = node_pool.name
    disk_size_gb      = node_pool.node_config[0].disk_size_gb
    disk_type         = node_pool.node_config[0].disk_type
    labels            = node_pool.node_config[0].labels
    ssd_count         = node_pool.node_config[0].local_ssd_count
    machine_type      = node_pool.node_config[0].machine_type
    metadata          = node_pool.node_config[0].metadata
    min_cpu_platform  = node_pool.node_config[0].min_cpu_platform
    preemptible       = node_pool.node_config[0].preemptible
    tags              = node_pool.node_config[0].tags
    taints            = node_pool.node_config[0].taint
  }]
}
