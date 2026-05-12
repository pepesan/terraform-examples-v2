variable "project_name" {}
variable "region" {}

provider "aws" {
  region = var.region
}
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  #version = "21.15.1"
  name = local.cluster_name
  # ojo con la versión, cobran más por versiones antiguas
  kubernetes_version = "1.35"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  # Optional
  endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true



  eks_managed_node_groups = {
    one = {
      name = "node-group-1"
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type                              = "AL2023_x86_64_STANDARD"
      attach_cluster_primary_security_group = false
      create_security_group                 = false
      instance_types                        = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      vpc_security_group_ids = [
        aws_security_group.node_group_one.id,
      ]
    }

    two = {
      name = "node-group-2"
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type                              = "AL2023_x86_64_STANDARD"
      attach_cluster_primary_security_group = false
      create_security_group                 = false
      instance_types                        = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      vpc_security_group_ids = [
        aws_security_group.node_group_two.id,
      ]
    }
  }
}



