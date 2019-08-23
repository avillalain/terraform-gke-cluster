variable "project_id" {}


variable "network" {
  type = object({
    name = string
  })
}

variable "subnetwork" {
  type = object({
    name       = string
    cidr_range = string
    region     = string
    secondary_ranges = list(object({
      name       = string
      cidr_range = string
    }))
  })
}

variable "cluster" {
  type = object({
    name     = string
    location = string
    addons = object({
      istio = object({
        enabled        = bool
        authentication = string
      })
      cloud_run = object({
        enabled = bool
      })
    })
    description         = string
    binary_auth_enabled = bool
    initial_node_count  = number
    ip_alias = object({
      pod_address_range_name     = string
      service_address_range_name = string
    })
    services = object({
      stackdriver_monitoring_enabled = bool
    })
    maintenance_window = string
    master_cidr_block = string
    authorized_networks = list(object({
      cidr_block = string
      name       = string
    }))
    cluster_version = string
    labels          = map(string)
  })
}

variable "node_pools" {
  type = list(object({
    min_nodes               = number
    max_nodes               = number
    max_pods_per_node       = number
    name                    = string
    disk_size_gb            = number
    disk_type               = string
    labels                  = map(string)
    ssd_count               = number
    machine_type            = string,
    metadata                = map(string)
    min_cpu_platform        = string
    preemptible             = bool
    tags                    = list(string)
    taints = list(object({
      effect = string
      key    = string
      value  = string
    }))
  }))
}

variable "service_account" {
  type = object({
    name = string
    description = string
    additional_roles = list(string)
  })
}