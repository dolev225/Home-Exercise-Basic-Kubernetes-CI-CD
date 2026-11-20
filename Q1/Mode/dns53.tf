# ---------------------------------------------------------------------------
# Route 53 + ACM for dolev-demoapp.com
# ---------------------------------------------------------------------------
# Prerequisites:
# - Domain dolev-demoapp.com must be registered and in Successful status
# - A public Hosted Zone for the domain must exist (created automatically
#   by Route 53 when the domain registration completes)
# ---------------------------------------------------------------------------

variable "domain_name" {
  description = "Root domain name (must be registered in Route 53)"
  type        = string
  default     = "dolev-demoapp.com"
}

variable "enable_dns_tls" {
  description = "Create ACM certificate and Route53 records"
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Hosted Zone (data source – assumes it already exists after domain registration)
# ---------------------------------------------------------------------------
data "aws_route53_zone" "main" {
  count = var.enable_dns_tls ? 1 : 0

  name         = var.domain_name
  private_zone = false
}

# ---------------------------------------------------------------------------
# ACM Certificate
# ---------------------------------------------------------------------------
resource "aws_acm_certificate" "app" {
  count = var.enable_dns_tls ? 1 : 0

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.domain_name}-cert"
  }
}

# ---------------------------------------------------------------------------
# DNS Validation Records
# ---------------------------------------------------------------------------
resource "aws_route53_record" "cert_validation" {
  for_each = var.enable_dns_tls ? {
    for dvo in aws_acm_certificate.app[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main[0].zone_id
}

resource "aws_acm_certificate_validation" "app" {
  count = var.enable_dns_tls ? 1 : 0

  certificate_arn         = aws_acm_certificate.app[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# ---------------------------------------------------------------------------
# Alias record pointing to the ALB (optional – can also be created manually)
# Uncomment and wire the ALB DNS name / zone id when ready
# ---------------------------------------------------------------------------
# resource "aws_route53_record" "app" {
#   count = var.enable_dns_tls ? 1 : 0
#
#   zone_id = data.aws_route53_zone.main[0].zone_id
#   name    = var.domain_name
#   type    = "A"
#
#   alias {
#     name                   = var.alb_dns_name          # pass from root module
#     zone_id                = var.alb_zone_id           # pass from root module
#     evaluate_target_health = true
#   }
# }

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------
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
