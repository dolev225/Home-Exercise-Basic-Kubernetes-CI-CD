module "my_infrastructure" {

  source = "./Mode/"


}

resource "helm_release" "node_app" {
  name             = "my-node-app"
  chart            = "./helm"
  namespace        = "default"
  create_namespace = true

  set {
    name  = "image.repository"
    value = "dolev1234/node-demo-local"
  }

  set {
    name  = "image.tag"
    value = "latest"
  }
}
#print

#ADD1