output "cluster_endpoint" {
  description = "EKS control plane endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "configure_kubectl" {
  description = "Command to update kubeconfig for kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}