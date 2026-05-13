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
      before_compute = true # debe estar listo antes de que los nodos arranquen para que los pods tengan identidad desde el primer segundo
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true # idem: sin el CNI los pods no tienen red; instalarlo antes evita que los nodos queden en NotReady
    }
  }

  endpoint_public_access = true # permite acceder a la API de Kubernetes desde fuera de la VPC (necesario para kubectl desde el portátil)

  enable_cluster_creator_admin_permissions = true # añade la identidad IAM que ejecuta Terraform como admin del cluster vía access entry

  eks_managed_node_groups = {
    one =   {
      name                                  = "node-group-1"
      ami_type                              = "AL2023_x86_64_STANDARD"
      attach_cluster_primary_security_group = false # no adjuntar el SG del cluster a los nodos; gestionamos el acceso con nuestros propios SGs
      create_security_group                 = false # idem: el módulo no crea SG adicional, usamos los definidos en security-groups.tf
      instance_types                        = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      vpc_security_group_ids = [
        aws_security_group.node_group_one.id,
        aws_security_group.node_service.id # permite tráfico al NodePort 30201 para exponer servicios vía NLB
      ]
    }

    two = {
      name                                  = "node-group-2"
      ami_type                              = "AL2023_x86_64_STANDARD"
      attach_cluster_primary_security_group = false
      create_security_group                 = false
      instance_types                        = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      vpc_security_group_ids = [
        aws_security_group.node_group_two.id,
        aws_security_group.node_service.id
      ]
    }
  }
}



