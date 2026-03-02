provider "google" {
  project = var.project_id
  region  = var.region
}

# --- API ---
resource "google_project_service" "compute" {
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "container" {
  project    = var.project_id
  service    = "container.googleapis.com"
  depends_on = [google_project_service.compute]
}

# --- NETWORK ---
resource "google_compute_network" "vpc" {
  name                     = var.vpc_name
  auto_create_subnetworks  = false
  routing_mode             = "REGIONAL"
  enable_ula_internal_ipv6 = var.stack_type == "IPV4_IPV6" && var.ipv6_access_type == "INTERNAL" ? true : false
}

resource "google_compute_subnetwork" "subnet" {
  name                       = var.subnet_name
  region                     = var.region
  network                    = google_compute_network.vpc.id
  ip_cidr_range              = var.subnet_cidr
  private_ip_google_access   = var.private_ip_google_access

  # IPv6 configuration (only applied when stack_type = IPV4_IPV6)
  stack_type                 = var.stack_type
  ipv6_access_type           = var.stack_type == "IPV4_IPV6" ? var.ipv6_access_type : null
  private_ipv6_google_access = var.stack_type == "IPV4_IPV6" ? var.private_ipv6_google_access : null
}

# --- CLUSTER ---
resource "google_container_cluster" "cluster" {
  name       = var.cluster_name
  location   = var.zone
  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  min_master_version = var.kubernetes_version
  datapath_provider  = var.datapath_provider
  networking_mode    = var.networking_mode

  # Disable GKE managed monitoring to reduce costs and avoid automatic metric collection
  monitoring_config {
    enable_components = []
    managed_prometheus {
      enabled = false
    }
  }

  # disable all logging
  logging_config {
    enable_components = []
  }

  # Enable L4 ILB subsetting for optimized traffic routing to nodes with actual pods,
  # reducing network hops and improving performance for internal Load Balancers
  enable_l4_ilb_subsetting = true

  # Remove default node pool immediately after cluster creation
  # We'll create a separate managed node pool with custom instances
  remove_default_node_pool = true
  initial_node_count       = 1 # Required for cluster creation, will be removed

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = var.pods_cidr
    services_ipv4_cidr_block = var.services_cidr
    stack_type               = var.stack_type
  }

  addons_config {
    http_load_balancing {
      disabled = false # Enable "HTTP Load Balancing"
    }

    network_policy_config {
      disabled = true
    }
  }

  release_channel {
    channel = var.channel
  }

  # Allow cluster deletion without additional confirmation
  deletion_protection = false

  depends_on = [google_project_service.container]
}

resource "google_container_node_pool" "primary" {
  name       = var.node_pool_name
  cluster    = google_container_cluster.cluster.id
  location   = google_container_cluster.cluster.location
  node_count = var.node_count

  node_config {
    spot         = var.enable_spot_instances ? true : false
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type
    image_type   = var.image_type

    # Metadata to disable GKE node logging to save costs
    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  # Enable automatic node management
  management {
    auto_upgrade = var.auto_upgrade
    auto_repair  = var.auto_repair
  }

  # Autoscaling configuration
  dynamic "autoscaling" {
    for_each = var.enable_node_pool_autoscaling ? [] : [1]
    content {
      min_node_count = var.min_node_count
      max_node_count = var.max_node_count
    }
  }

  # Upgrade settings to minimize disruption
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}