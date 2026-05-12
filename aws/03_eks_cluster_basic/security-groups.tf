resource "aws_security_group" "node_group_one" {
  name_prefix = "node_group_one"
  vpc_id      = module.vpc.vpc_id
  tags        = { Name = "${local.cluster_name}-node-group-one" }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }

  # Terraform elimina la regla de egress por defecto de AWS al crear un SG.
  # Con attach_cluster_primary_security_group = false, el SG del cluster no se
  # adjunta a los nodos, por lo que hay que definir el egress explícitamente.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "node_service" {
  name_prefix = "node_service_nginx"
  vpc_id      = module.vpc.vpc_id
  tags        = { Name = "${local.cluster_name}-node-service" }

  ingress {
    from_port = 30201
    to_port   = 30201
    protocol  = "tcp"
    # los nodos están en subnets privadas; aunque el CIDR es 0.0.0.0/0,
    # solo es alcanzable desde dentro de la VPC o a través del NLB
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "node_group_two" {
  name_prefix = "node_group_two"
  vpc_id      = module.vpc.vpc_id
  tags        = { Name = "${local.cluster_name}-node-group-two" }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }

  # Mismo motivo que node_group_one: egress explícito necesario.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}