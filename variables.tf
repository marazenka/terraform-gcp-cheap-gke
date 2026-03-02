variable "project_id" {
  type        = string
  description = "The ID of the Google Cloud project where the Autopilot cluster will be created."
}

variable "enable_spot_instances" {
  type        = bool
  description = "Enable spot (preemptible) instances for the node pool to reduce costs."
  default     = true
}

variable "enable_node_pool_autoscaling" {
  type        = bool
  description = "Enable autoscaling for the node pool."
  default     = true
}

variable "region" {
  type        = string
  description = "The region for network resources (VPC, subnet)."
}

variable "zone" {
  type        = string
  description = "The zone where the zonal GKE cluster will be created (cheapest option)."
}

variable "cluster_name" {
  type        = string
  description = "The name of the GKE cluster."
}

variable "subnet_cidr" {
  type        = string
  description = "The CIDR block for the subnet."

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "CIDR block parameter must be in the form x.x.x.x/16-28."
  }
}

variable "pods_cidr" {
  type        = string
  description = "The CIDR block for the pods."

  validation {
    condition     = can(cidrhost(var.pods_cidr, 0))
    error_message = "CIDR block parameter must be in the form x.x.x.x/16-28."
  }
}

variable "services_cidr" {
  type        = string
  description = "The CIDR block for the services."

  validation {
    condition     = can(cidrhost(var.services_cidr, 0))
    error_message = "CIDR block parameter must be in the form x.x.x.x/16-28."
  }
}

variable "vpc_name" {
  type        = string
  description = "The name of the VPC network (existing or to be created)."
  default     = "vpc1"
}

variable "subnet_name" {
  type        = string
  description = "The name of the subnet (existing or to be created)."
  default     = "subnet1"
}


variable "kubernetes_version" {
  type        = string
  description = "The Kubernetes version for the GKE cluster."
  default     = "1.33"
}

# ===== NODE POOL CONFIGURATION =====
variable "node_pool_name" {
  type        = string
  description = "The name of the primary node pool."
  default     = "primary-pool"
}

variable "node_count" {
  type        = number
  description = "Initial number of nodes in the node pool."
  default     = 1
}

variable "min_node_count" {
  type        = number
  description = "Minimum number of nodes for autoscaling."
  default     = 1
}

variable "max_node_count" {
  type        = number
  description = "Maximum number of nodes for autoscaling."
  default     = 3
}

variable "machine_type" {
  type        = string
  description = "Machine type for node pool. For cheapest option use: e2-micro, e2-small, or e2-medium."
  default     = "e2-micro"
}

variable "disk_size_gb" {
  type        = number
  description = "Disk size in GB for node pool nodes. Minimum 12GB required for GKE images."
  default     = 15
}

variable "disk_type" {
  type        = string
  description = "Disk type for node pool. Options: pd-standard (cheapest), pd-balanced, pd-ssd."
  default     = "pd-standard"
}

variable "image_type" {
  type        = string
  description = "The image type for node pool. Options: COS_CONTAINERD, UBUNTU_CONTAINERD."
  default     = "COS_CONTAINERD"

  validation {
    condition     = contains(["COS_CONTAINERD", "UBUNTU_CONTAINERD"], var.image_type)
    error_message = "Invalid image_type. Allowed values are COS_CONTAINERD or UBUNTU_CONTAINERD."
  }
}

variable "auto_upgrade" {
  type        = bool
  description = "Enable automatic node upgrades."
  default     = true
}

variable "auto_repair" {
  type        = bool
  description = "Enable automatic node repair."
  default     = true
}

variable "private_ip_google_access" {
  type        = bool
  description = "Whether to enable Private Google Access for IPv4 (allows VMs without external IPs to access Google APIs)."
  default     = true
}

variable "stack_type" {
  type        = string
  description = "IP stack type for the subnet and cluster. IPV4_ONLY = IPv4 only. IPV4_IPV6 = dual-stack (IPv4 + IPv6)."
  default     = "IPV4_ONLY"

  validation {
    condition     = contains(["IPV4_ONLY", "IPV4_IPV6"], var.stack_type)
    error_message = "Invalid stack_type. Allowed values are IPV4_ONLY or IPV4_IPV6."
  }
}

variable "ipv6_access_type" {
  type        = string
  description = "IPv6 access type for the subnet. Used only when stack_type = IPV4_IPV6. EXTERNAL = public IPv6 (GUA), INTERNAL = private IPv6 (only within VPC/Interconnect)."
  default     = "EXTERNAL"

  validation {
    condition     = contains(["INTERNAL", "EXTERNAL"], var.ipv6_access_type)
    error_message = "Invalid ipv6_access_type. Allowed values are INTERNAL or EXTERNAL."
  }
}

variable "private_ipv6_google_access" {
  type        = string
  description = "Private IPv6 Google access type. Used only when stack_type = IPV4_IPV6. Options: DISABLE_GOOGLE_ACCESS, ENABLE_BIDIRECTIONAL_ACCESS_TO_GOOGLE, ENABLE_OUTBOUND_VM_ACCESS_TO_GOOGLE."
  default     = "DISABLE_GOOGLE_ACCESS"

  validation {
    condition     = contains(["DISABLE_GOOGLE_ACCESS", "ENABLE_BIDIRECTIONAL_ACCESS_TO_GOOGLE", "ENABLE_OUTBOUND_VM_ACCESS_TO_GOOGLE"], var.private_ipv6_google_access)
    error_message = "Invalid private_ipv6_google_access. Allowed values are DISABLE_GOOGLE_ACCESS, ENABLE_BIDIRECTIONAL_ACCESS_TO_GOOGLE, ENABLE_OUTBOUND_VM_ACCESS_TO_GOOGLE."
  }
}

variable "networking_mode" {
  type        = string
  description = "The networking mode for the GKE cluster. Options are VPC_NATIVE or ROUTE_BASED."
  default     = "VPC_NATIVE"

  validation {
    condition     = contains(["VPC_NATIVE", "ROUTE_BASED"], var.networking_mode)
    error_message = "Invalid networking mode. Allowed values are VPC_NATIVE or ROUTE_BASED."
  }
}

variable "channel" {
  type        = string
  description = "The release channel for the GKE cluster. Options are RAPID, REGULAR, STABLE, or NONE."
  default     = "REGULAR"

  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE", "NONE"], var.channel)
    error_message = "Invalid channel. Allowed values are RAPID, REGULAR, STABLE, or NONE."
  }
}


variable "datapath_provider" {
  type        = string
  description = "The datapath provider for the GKE cluster. Options are LEGACY_DATAPATH or ADVANCED_DATAPATH."
  default     = "LEGACY_DATAPATH"

  validation {
    condition     = contains(["LEGACY_DATAPATH", "ADVANCED_DATAPATH"], var.datapath_provider)
    error_message = "Invalid datapath_provider. Allowed values are LEGACY_DATAPATH or ADVANCED_DATAPATH."
  }
}

