resource "aws_security_group" "node_group_one" {
  name_prefix = "node_group_one"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }
}
resource "aws_security_group" "node_service" {
  name_prefix = "node_service_nginx"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 30201
    to_port   = 30201
    protocol  = "tcp"

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

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "192.168.0.0/16",
    ]
  }
}