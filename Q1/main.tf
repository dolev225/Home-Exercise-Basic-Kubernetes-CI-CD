module "my_infrastructure" {
  source = "./Mode"

  aws_region        = var.aws_region
  environment       = var.environment
  owner             = var.owner
  cost_center       = var.cost_center
  cluster_name      = var.cluster_name
  pipeline_role_arn = var.pipeline_role_arn
}


resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.9.0"

  set {
    name  = "clusterName"
    value = module.my_infrastructure.cluster_name
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = module.my_infrastructure.vpc_id
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  # IRSA: ties the Kubernetes service account to the IAM role
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.my_infrastructure.alb_controller_role_arn
  }
}


resource "helm_release" "node_app" {
  name             = "my-node-app"
  chart            = "./helm"
  namespace        = "default"
  create_namespace = true

  set {
    name  = "image.repository"
    value = var.image_repository
  }

  set {
    name  = "image.tag"
    value = var.image_tag
  }

  # The Ingress is validated by the LB controller's webhook, so it must be running first
  depends_on = [helm_release.aws_lb_controller]
}


locals {
  ingress_annotations = merge(
    {
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/"
      "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\": 80}]"
    },
    var.enable_dns_tls ? {
      "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
      "alb.ingress.kubernetes.io/certificate-arn" = one(aws_acm_certificate_validation.app[*].certificate_arn)
    } : {}
  )
}

resource "kubernetes_ingress_v1" "node_app_ingress" {
  metadata {
    name        = "my-node-app-ingress"
    namespace   = "default"
    annotations = local.ingress_annotations
  }

  wait_for_load_balancer = true

  spec {
    ingress_class_name = "alb"

    rule {

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "my-node-app-svc" 
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.aws_lb_controller,
    helm_release.node_app
  ]
}

output "alb_hostname" {
  description = "ALB DNS name. Point demoapp.com to it in your hosts file if DNS is disabled."
  value       = try(kubernetes_ingress_v1.node_app_ingress.status[0].load_balancer[0].ingress[0].hostname, null)
}

# ---------------------------------------------------------------------------
# Optional DNS + TLS (enable_dns_tls = true)
# Needs a public Route53 zone for var.domain_name that you actually own.
# ---------------------------------------------------------------------------

data "aws_route53_zone" "main" {
  count        = var.enable_dns_tls ? 1 : 0
  name         = var.domain_name
  private_zone = false
}

resource "aws_acm_certificate" "app" {
  count             = var.enable_dns_tls ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = var.enable_dns_tls ? {
    for dvo in aws_acm_certificate.app[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id         = data.aws_route53_zone.main[0].zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "app" {
  count                   = var.enable_dns_tls ? 1 : 0
  certificate_arn         = aws_acm_certificate.app[0].arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

data "aws_lb_hosted_zone_id" "alb" {
  count = var.enable_dns_tls ? 1 : 0
}

# A zone apex cannot be a CNAME, so use an alias A record pointing to the ALB
resource "aws_route53_record" "app" {
  count   = var.enable_dns_tls ? 1 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = kubernetes_ingress_v1.node_app_ingress.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_lb_hosted_zone_id.alb[0].id
    evaluate_target_health = true
  }
}