# Default Security Group
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.informe_nube.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name     = "Default"
    Episodio = "Informe Nube 4"
  }

  depends_on = [aws_vpc.informe_nube]
}

# Security Group
resource "aws_security_group" "servidor_web" {
  name        = "Servidor Web"
  description = "Grupo de seguridad para las intancias EC2"
  vpc_id      = aws_vpc.informe_nube.id

  tags = {
    Name     = "Servidor Web"
    Episodio = "Informe Nube 4"
  }
}

resource "aws_security_group_rule" "http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.servidor_web.id
  description       = "Permitir conexiones al puerto HTTP desde cualquier IP"

  depends_on = [aws_security_group.servidor_web]
}

resource "aws_security_group_rule" "https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.servidor_web.id
  description       = "Permitir conexiones al puerto HTTP desde cualquier IP"

  depends_on = [aws_security_group.servidor_web]
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.servidor_web.id
  description       = "Permitir conexiones al puerto SSH desde cualquier IP"

  depends_on = [aws_security_group.servidor_web]
}

# Security Group
resource "aws_security_group" "efs" {
  name        = "EFS"
  description = "Grupo de seguridad para el disco EFS"
  vpc_id      = aws_vpc.informe_nube.id

  tags = {
    Name     = "EFS"
    Episodio = "Informe Nube 4"
  }
}

resource "aws_security_group_rule" "efs" {
  count             = length(data.aws_availability_zones.available.zone_ids)
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  cidr_blocks       = [element(aws_subnet.public[*].cidr_block, count.index)]
  security_group_id = aws_security_group.efs.id
  description       = "Permitir conexiones al puerto HTTP desde cualquier IP"

  depends_on = [aws_security_group.efs]
}