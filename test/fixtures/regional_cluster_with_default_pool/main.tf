
provider "google" {
  version = "~> 2.12.0"
}

provider "google-beta" {
  version = "~> 2.12.0"
}

resource "google_compute_network" "network" {
  provider                        = google
  name                            = var.network.name
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = false
}

resource "google_compute_subnetwork" "subnetwork" {
  provider                 = google
  name                     = var.subnetwork["name"]
  network                  = google_compute_network.network.self_link
  region                   = var.subnetwork["region"]
  ip_cidr_range            = var.subnetwork["cidr_range"]
  private_ip_google_access = true
  enable_flow_logs         = false

  dynamic "secondary_ip_range" {
    for_each = [for range in var.subnetwork["secondary_ranges"] : {
      name  = range.name
      cidr_range = range.cidr_range
    }]
    content {
      range_name    = lookup(secondary_ip_range.value, "name", null)
      ip_cidr_range = lookup(secondary_ip_range.value, "cidr_range", null)
    }
  }
}


module "cluster" {
  source = "../../../"
  cluster = {
    name       = var.cluster.name
    location   = var.cluster.location
    network    = google_compute_network.network.self_link
    subnetwork = google_compute_subnetwork.subnetwork.self_link
    addons = {
      istio = {
        enabled = var.cluster.addons.istio.enabled
        authentication = var.cluster.addons.istio.authentication
      }
      cloud_run = {
        enabled = var.cluster.addons.cloud_run.enabled
      }
    }
    description         = var.cluster.description
    binary_auth_enabled = var.cluster.binary_auth_enabled
    initial_node_count  = var.cluster.initial_node_count
    ip_alias            = var.cluster.ip_alias
    services            = var.cluster.services
    maintenance_window  = var.cluster.maintenance_window
    master_cidr_block   = var.cluster.master_cidr_block
    authorized_networks = var.cluster.authorized_networks
    cluster_version     = var.cluster.cluster_version
    labels              = var.cluster.labels
  }
  node_pools = var.node_pools
  service_account = var.service_account
}
