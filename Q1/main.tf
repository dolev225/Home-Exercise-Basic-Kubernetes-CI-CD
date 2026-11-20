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
  count = var.deploy_apps ? 1 : 0

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.9.0"

  timeout = 900
  wait    = true

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

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.my_infrastructure.alb_controller_role_arn
  }

  depends_on = [
    module.my_infrastructure
  ]
}

resource "helm_release" "node_app" {
  count = var.deploy_apps ? 1 : 0

  name             = "my-node-app"
  chart            = "./helm"
  namespace        = "default"
  create_namespace = true

  timeout = 900
  wait    = true

  set {
    name  = "image.repository"
    value = var.image_repository
  }

  set {
    name  = "image.tag"
    value = var.image_tag
  }

  depends_on = [helm_release.aws_lb_controller]
}

locals {
  ingress_annotations = {
    "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
    "alb.ingress.kubernetes.io/target-type"      = "ip"
    "alb.ingress.kubernetes.io/healthcheck-path" = "/"
    "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\": 80}]"
  }
}

resource "kubernetes_ingress_v1" "node_app_ingress" {
  count = var.deploy_apps ? 1 : 0

  metadata {
    name        = "my-node-app-ingress"
    namespace   = "default"
    annotations = local.ingress_annotations
  }

  wait_for_load_balancer = true

  timeouts {
    create = "15m"
  }

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
  description = "ALB DNS name"
  value       = try(kubernetes_ingress_v1.node_app_ingress[0].status[0].load_balancer[0].ingress[0].hostname, null)
}



