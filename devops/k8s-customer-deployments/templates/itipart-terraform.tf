variable "cluster_ips" {
  type        = list(string)
  description = "List of cluster IP addresses for ITIPART deployment"
  default     = ["10.0.0.1", "10.0.0.2", "10.0.0.3"]
}

variable "fnfe_image_tag" {
  type        = string
  description = "Docker image tag for fnfe repository"
  default     = "latest"
}

variable "replica_count" {
  type        = number
  description = "Number of replicas for ITIPART deployment"
  default     = 2
}

output "itipart_service_endpoint" {
  description = "Endpoint for ITIPART service"
  value       = "itipart-service.itipart.svc.cluster.local"
}

output "cluster_ips" {
  description = "Cluster IPs used for ITIPART deployment"
  value       = var.cluster_ips
}