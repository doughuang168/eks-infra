module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "~> 20.0"

  #https://github.com/atmosly/opentofu-aws-eks/blob/main/README.md
  #source          = "git@github.com:atmosly/opentofu-aws-eks.git"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"
  subnet_ids      = aws_subnet.private.*.id 

  tags = {
    Environment = "example"
  }

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id = aws_vpc.main.id

  eks_managed_node_groups = {
      worker-group-1 = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t2.small"]

      min_size     = 2
      max_size     = 2
      desired_size = 2
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
    }
      worker-group-2 = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t2.medium"]

      min_size     = 1
      max_size     = 1
      desired_size = 1
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_two.id]
    }
  }


  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  cluster_endpoint_private_access      = false # or true for private access

  cluster_endpoint_public_access       = true 
  #cluster_endpoint_public_access_cidrs = local.public_subnets


}


## Have to wait eks module finish
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
  depends_on = [ module.eks ]
}

## Have to wait eks module finish
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
  depends_on = [ module.eks ]
}


