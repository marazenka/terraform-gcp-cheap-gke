# terraform-gcp-cheap-gke

This project automates the deployment of a cost-optimized Google Kubernetes Engine (GKE) cluster designed for learning, development, and testing environments. The configuration focuses on minimizing costs while maintaining a functional Kubernetes cluster.

## Features

- Automated provisioning of a zonal GKE cluster with free control plane
- Spot (preemptible) instances for up to 91% cost savings on compute
- Minimal resource allocation (e2-micro instances, standard disks)
- Autoscaling configuration with ability to scale to zero nodes
- Flexible networking: IPv4-only (default) or dual-stack IPv4+IPv6
- Optional IPv6 support with configurable access type (EXTERNAL/INTERNAL)
- Disabled monitoring and logging to avoid additional charges
- Infrastructure as Code using Terraform for reproducible deployments

## Prerequisites

Before running this Terraform configuration, ensure the following are installed and configured on your local machine:

- **Google Cloud Account**: You need an active Google Cloud account with billing enabled. Sign up at [cloud.google.com](https://cloud.google.com/).
- **Terraform or OpenTofu**: Version 1.0 or later. Download Terraform from [terraform.io](https://www.terraform.io/downloads) or OpenTofu from [opentofu.org](https://opentofu.org/). This project is compatible with both.
- **Google Cloud SDK** (`gcloud` CLI): Install from [cloud.google.com/sdk](https://cloud.google.com/sdk/docs/install).
  - Authenticate with your Google Cloud account: `gcloud auth application-default login`
  - Set your project: `gcloud config set project YOUR_PROJECT_ID`
  - Enable required APIs: `gcloud services enable compute.googleapis.com container.googleapis.com`
- **kubectl**: Kubernetes command-line tool. Install from [kubernetes.io/docs/tasks/tools](https://kubernetes.io/docs/tasks/tools/) or via `gcloud components install kubectl`.

## Cost Considerations

Using Google Cloud resources incurs costs. This configuration is optimized for minimal expense:

| Component | Configuration | Estimated Monthly Cost |
|-----------|--------------|------------------------|
| Control Plane | Zonal cluster | $0 (FREE) |
| Compute | 1x e2-micro spot instance | ~$1.83 |
| Disk | 15GB pd-standard | ~$0.60 |
| Network | Minimal egress | ~$0-1 |
| **TOTAL** | | **~$2.43-3.43** |

Key cost factors:
- VM Instances: Charged per hour. Spot instances provide up to 91% savings but can be preempted.
- Disks: Charged for storage allocation.
- Network: Egress charges apply when traffic leaves GCP.

Monitor usage in the [GCP Billing Console](https://console.cloud.google.com/billing). Always destroy resources when not in use:

```bash
terraform destroy
```

## Cost Optimization Strategies

### 1. Zonal Cluster
Using a zonal cluster instead of regional provides a free control plane (saves ~$73/month). Trade-off: lower availability as the cluster runs in a single zone.

### 2. Spot Instances
Spot VMs are up to 91% cheaper than regular instances. Trade-off: they can be preempted at any time with 30 seconds notice.

### 3. Minimal Machine Type
`e2-micro` (2 vCPU, 1GB RAM) is the cheapest machine type available and sufficient for learning and simple workloads.

### 4. Standard Disks
`pd-standard` disks are the most cost-effective option. The configuration uses the minimum size required by GKE (15GB recommended, 12GB absolute minimum).

### 5. Disabled Monitoring and Logging
GKE monitoring and logging are disabled to avoid Cloud Logging and Cloud Monitoring costs.

### 6. Legacy Datapath
Using `LEGACY_DATAPATH` instead of `ADVANCED_DATAPATH` avoids additional networking costs.

### 7. Autoscaling to Zero
The node pool can scale down to zero nodes when no workloads are running, eliminating compute costs during idle periods.

## Installation

1. Clone this repository:

```bash
git clone <repository-url>
cd terraform-gcp-cheap-gke
```

2. Copy and edit the variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
project_id = "your-project-id"
zone       = "us-central1-a"  # Choose nearest zone
region     = "us-central1"
```

3. Initialize Terraform:

```bash
terraform init
```

4. Validate the configuration:

```bash
terraform validate
```

5. Plan the deployment:

```bash
terraform plan
```

6. Apply the configuration:

```bash
terraform apply
```

## Configuration

Edit `terraform.tfvars` to customize your cluster:

- `project_id`: Your GCP project identifier
- `region` and `zone`: Geographic location (zonal clusters are cheaper)
- `cluster_name`: Name for your GKE cluster
- `machine_type`: Instance type (`e2-micro`, `e2-small`, `e2-medium`)
- `enable_spot_instances`: Use spot VMs for cost savings
- `min_node_count` and `max_node_count`: Autoscaling limits
- `disk_size_gb` and `disk_type`: Storage configuration

### IPv6 / Dual-Stack

By default the cluster runs IPv4-only (`stack_type = "IPV4_ONLY"`). To enable dual-stack:

```hcl
# Enable dual-stack (IPv4 + IPv6)
stack_type = "IPV4_IPV6"

# EXTERNAL = public GUA IPv6 (2600:1900::/28), routable from the internet
# INTERNAL = private IPv6, accessible only within VPC / Cloud Interconnect
ipv6_access_type = "EXTERNAL"

# Optional: allow nodes to reach Google APIs over IPv6
private_ipv6_google_access = "ENABLE_OUTBOUND_VM_ACCESS_TO_GOOGLE"
```

No additional IPv6 CIDR ranges are needed — GCP automatically assigns a `/64` to the subnet and allocates ranges for pods and services.

## Usage

### Configure kubectl

After deployment, configure `kubectl` to access your cluster:

```bash
gcloud container clusters get-credentials <cluster-name> \
  --zone=<zone> \
  --project=<project-id>
```

### Verify cluster

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

### Deploy sample application

```bash
kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0
kubectl expose deployment hello-server --type=LoadBalancer --port 80 --target-port 8080
```

Wait for external IP:

```bash
kubectl get services hello-server
```

### Scale to zero

When not using the cluster, scale to zero to stop billing:

```bash
terraform apply -var="node_count=0" -auto-approve
```

### Destroy infrastructure

When finished with the cluster:

```bash
terraform destroy
```

To execute in non-interactive mode:

```bash
terraform destroy -auto-approve
```

## Variables

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `project_id` | GCP Project ID | string | - |
| `region` | GCP Region for VPC resources | string | - |
| `zone` | GCP Zone for cluster (zonal = cheaper) | string | - |
| `cluster_name` | Name of the GKE cluster | string | - |
| `machine_type` | VM instance type | string | `e2-small` |
| `disk_size_gb` | Boot disk size in GB | number | `12` |
| `disk_type` | Disk type (`pd-standard` recommended) | string | `pd-standard` |
| `enable_spot_instances` | Use spot VMs for cost savings | bool | `true` |
| `min_node_count` | Minimum nodes for autoscaling | number | `1` |
| `max_node_count` | Maximum nodes for autoscaling | number | `3` |
| `kubernetes_version` | Kubernetes version | string | `1.33` |
| `stack_type` | IP stack: `IPV4_ONLY` or `IPV4_IPV6` (dual-stack) | string | `IPV4_ONLY` |
| `ipv6_access_type` | IPv6 access type: `EXTERNAL` or `INTERNAL` | string | `EXTERNAL` |
| `private_ipv6_google_access` | IPv6 access to Google APIs | string | `DISABLE_GOOGLE_ACCESS` |

## Outputs

After deployment, the following outputs are available:

- `cluster_name`: Name of the created GKE cluster
- `cluster_location`: Zone where the cluster is deployed
- `cluster_endpoint`: API endpoint for the cluster (sensitive)
- `node_pool_name`: Name of the primary node pool
- `kubeconfig_command`: Command to configure `kubectl` access
- `next_steps`: Detailed instructions for using the cluster

## Project Structure

- `main.tf`: Main Terraform configuration for GKE cluster and networking
- `variables.tf`: Input variable definitions
- `terraform.tfvars`: Variable values (customize this file)
- `outputs.tf`: Output definitions
- `provider.tf`: Google Cloud provider configuration
- `README.md`: This documentation

## Limitations

1. Spot VMs can be preempted at any time, causing temporary disruptions
2. `e2-micro` instances have limited resources (1GB RAM, 2 vCPU)
3. Zonal clusters provide no high availability across zones
4. Monitoring and logging are disabled to reduce costs
5. Not suitable for production workloads requiring reliability

## Working with Spot Instances

Spot instances are configured without taints by default, allowing all pods to schedule on them. For production-like scenarios where you want to control pod placement, you can add taints to spot nodes in `main.tf`:

```hcl
taint {
  key    = "cloud.google.com/gke-spot"
  value  = "true"
  effect = "NO_SCHEDULE"
}
```

Then configure pod tolerations:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  tolerations:
  - key: "cloud.google.com/gke-spot"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
  containers:
  - name: nginx
    image: nginx
```

For learning and development, running without taints is simpler and works fine.

## Troubleshooting

- Ensure your Google Cloud project has billing enabled
- Verify you have sufficient quota for the selected machine type and region
- Check that required APIs are enabled: `gcloud services list --enabled`
- If cluster creation fails, review Terraform error messages for specific issues
- For `kubectl` connection issues, regenerate credentials with the `gcloud` command

## Contributing

Contributions are welcome! If you have ideas for further cost optimization or improvements, please open an issue or submit a pull request.