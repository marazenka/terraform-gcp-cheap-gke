output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.cluster.name
}

output "cluster_location" {
  description = "The location (zone) of the GKE cluster"
  value       = google_container_cluster.cluster.location
}

output "cluster_endpoint" {
  description = "The endpoint for the GKE cluster"
  value       = google_container_cluster.cluster.endpoint
  sensitive   = true
}

output "node_pool_name" {
  description = "The name of the primary node pool"
  value       = google_container_node_pool.primary.name
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.cluster.name} --zone=${google_container_cluster.cluster.location} --project=${var.project_id}"
}

output "next_steps" {
  description = "Next steps to use your cluster"
  value       = <<-EOT
  
  NEXT STEPS:
  
  1. Configure kubectl:
     gcloud container clusters get-credentials ${google_container_cluster.cluster.name} --zone=${google_container_cluster.cluster.location} --project=${var.project_id}
  
  2. Verify cluster:
     kubectl get nodes
     kubectl get pods --all-namespaces
  
  3. Deploy your first app:
      kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0
      kubectl expose deployment hello-server --type=LoadBalancer --port 80 --target-port 8080
  
  4. Verify the app is running:
      kubectl get services hello-server
     (Wait for EXTERNAL-IP to appear, then visit in browser)

  5. When done working, scale to 0 to stop billing:
     terraform apply -var="node_count=0" -auto-approve
  
  6. Delete deployment when finished:
     kubectl delete service hello-server
     kubectl delete deployment hello-server

  7. To destroy everything:
     terraform destroy -auto-approve
  
  Full documentation: See README.md
  
  EOT
}
