data "google_compute_regions" "regions" {}

data "google_compute_zones" "zones" {
  count  = length(data.google_compute_regions.regions.names)
  region = data.google_compute_regions.regions.names[count.index]
}

data "google_container_engine_versions" "versions" {
  location = var.cluster.location
}

locals {
  is_regional                    = contains(data.google_compute_regions.regions.names, var.cluster.location)
  is_zonal                       = ! local.is_regional
  region_zones                   = local.is_regional ? flatten([for zone in data.google_compute_zones.zones : zone.names if zone.region == var.cluster.location]) : null
  zones_within_regional_location = local.is_zonal ? flatten([for zone in data.google_compute_zones.zones : zone.names if contains(zone.names, var.cluster.location)]) : null
  node_locations                 = local.is_regional ? local.region_zones : [for zone in local.zones_within_regional_location : zone if zone != var.cluster.location]
  master_version                 = var.cluster.cluster_version != "latest" ? var.cluster.cluster_version : data.google_container_engine_versions.versions.latest_master_version
  logging_service                = var.cluster.services.stackdriver_monitoring_enabled ? "logging.googleapis.com/kubernetes" : "none"
  monitoring_service             = var.cluster.services.stackdriver_monitoring_enabled ? "monitoring.googleapis.com/kubernetes" : "none"
  delelete_default_pool          = length(var.node_pools) == 0 ? false : true
  node_pool_base_label           = { "cluster_name" = var.cluster.name }
  node_pool_base_metadata        = merge({ "cluster_name" = google_container_cluster.cluster.name },
                                         { "disable-legacy-endpoints" = true })
  node_pool_base_tags            = ["gke-${google_container_cluster.cluster.name}"]
  base_roles                     = ["roles/logging.logWriter", "roles/monitoring.metricWriter", "roles/monitoring.viewer", "roles/stackdriver.resourceMetadata.writer"]
  all_roles                      = distinct(concat(local.base_roles, var.service_account.additional_roles))
}
