resource "aws_security_group" "allow_rds_ports" {
  name        = "allow_rds_ports"
  description = "Allow inbound Mysql from any IP"
  vpc_id      = module.vpc.vpc_id

  #ssh access
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    # Restrict ingress to necessary IPs/ports.
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}