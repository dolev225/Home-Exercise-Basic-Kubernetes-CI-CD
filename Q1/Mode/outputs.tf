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
  description = "IAM role  for the AWS Load Balancer"
  value       = aws_iam_role.alb_controller.arn
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate (use in Ingress annotation)"
  value       = var.enable_dns_tls ? aws_acm_certificate.app[0].arn : null
}

output "route53_zone_id" {
  description = "Route 53 Hosted Zone ID"
  value       = var.enable_dns_tls ? data.aws_route53_zone.main[0].zone_id : null
}

output "domain_name" {
  description = "Domain name"
  value       = var.domain_name
}
