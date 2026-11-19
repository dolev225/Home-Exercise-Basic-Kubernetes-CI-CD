output "cluster_endpoint" {
  description = "EKS control plane endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_ca_data" {
  description = "Base64 cluster certificate authority data"
  value       = module.eks.cluster_certificate_authority_data
}

output "configure_kubectl" {
  description = "Command to update kubeconfig for kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "vpc_id" {
  description = "ID of the VPC created by the vpc module"
  value       = module.vpc.vpc_id
}

output "alb_controller_role_arn" {
  description = "IAM role ARN for the AWS Load Balancer Controller service account"
  value       = aws_iam_role.alb_controller.arn
}