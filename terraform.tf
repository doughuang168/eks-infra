
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "> 4.29.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.7.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.7"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }

    #https://discuss.hashicorp.com/t/no-resource-schema-found-for-local-file-in-terraform-cloud/34561/3
    local = {
      version = "~> 2.1"
    }
  }

  backend "http" {}

  required_version = ">= 1.3.0"
}

provider "aws" {
  ##region = var.aws_region
  region         = "us-east-2"
}


provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  exec {
    api_version = local.k8s_exec.api_version
    args        = local.k8s_exec.args
    command     = local.k8s_exec.command
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", local.name]
  }
}


provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.name]
    }
  }
}

