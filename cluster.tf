resource "google_container_cluster" "cluster" {
  provider       = "google-beta"
  name           = var.cluster.name
  location       = var.cluster.location
  project        = var.project
  node_locations = local.node_locations
  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }
    http_load_balancing {
      disabled = false
    }
    kubernetes_dashboard {
      disabled = true
    }
    network_policy_config {
      disabled = false
    }
    istio_config {
      disabled = ! var.cluster.addons.istio.enabled
      auth     = var.cluster.addons.istio.enabled ? lookup(var.cluster.addons.istio, "authentication", "AUTH_NONE") : null
    }
    cloudrun_config {
      disabled = ! var.cluster.addons.cloud_run.enabled
    }
  }
  cluster_autoscaling {
    enabled = false
  }
  description                 = var.cluster.description
  enable_binary_authorization = var.cluster.binary_auth_enabled
  initial_node_count          = var.cluster.initial_node_count
  ip_allocation_policy {
    use_ip_aliases                = true
    cluster_secondary_range_name  = var.cluster.ip_alias.pod_address_range_name
    services_secondary_range_name = var.cluster.ip_alias.service_address_range_name
  }
  logging_service = local.logging_service
  maintenance_policy {
    daily_maintenance_window {
      start_time = var.cluster.maintenance_window
    }
  }
  master_auth {
    username = ""
    password = ""
    client_certificate_config {
      issue_client_certificate = false
    }
  }
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = [for authorized_network in var.cluster.authorized_networks : {
        cidr_block   = authorized_network.cidr_block
        display_name = authorized_network.name
      }]
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }
  min_master_version = local.master_version
  monitoring_service = local.monitoring_service
  network            = var.cluster.network
  network_policy {
    enabled  = true
    provider = "CALICO"
  }
  node_config {
    service_account = google_service_account.service_account.email
  }
  pod_security_policy_config {
    enabled = true
  }
  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block  = var.cluster.master_cidr_block
  }
  remove_default_node_pool = local.delelete_default_pool
  resource_labels          = var.cluster.labels
  subnetwork               = var.cluster.subnetwork
  vertical_pod_autoscaling {
    enabled = false
  }
  enable_intranode_visibility = true
}

locals {
  cluster = merge(var.cluster, {
    "node_locations" = google_container_cluster.cluster.node_locations
    "cluster_version" = local.master_version
  })
}