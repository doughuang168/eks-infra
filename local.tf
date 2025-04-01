locals {
  name         = var.cluster_name
  cluster_name = var.cluster_name

  region = "us-east-2"  ##var.region
  ##azs    = var.azs

  issuer = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  k8s_exec = {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", local.name]
  }

  #tags = {
  #  Cluster = local.cluster_name
  #}
}

locals {
  kubeconfig = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = local.name
    clusters = [{
      name = local.name
      cluster = {
        certificate-authority-data = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
        server                     = data.aws_eks_cluster.cluster.endpoint
      }
    }]
    contexts = [{
      name = local.name
      context = {
        cluster = local.name
        user    = local.name
      }
    }]
    users = [{
      name = local.name
      user = {
        token = data.aws_eks_cluster_auth.cluster.token
      }
    }]
  })
}
