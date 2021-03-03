# Elastic IPS
resource "aws_eip" "multiple" {
  count = length(data.aws_availability_zones.available.zone_ids)
  vpc = true

  tags = {
    Name    = "IP elastica"
    Episodio = "Informe Nube 4"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_instance" "multiple" {
  count                       = length(data.aws_availability_zones.available.zone_ids)
  availability_zone           = element(data.aws_availability_zones.available.names, count.index)
  ami                         = "ami-022e8cc8f0d3c52fd" // AMI son regionales (distintas IDS por region)
  instance_type               = "t3a.small"
  subnet_id                   = aws_subnet.public[count.index].id
  vpc_security_group_ids      = concat([aws_security_group.servidor_web.id], [aws_default_security_group.default.id])
  key_name                    = aws_key_pair.devago.id

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "50"
    delete_on_termination = true
  }
#User data is limited to 16 KB
  user_data = <<-EOF
                #!/bin/bash
                # ---> Updating, upgrating and installing the base
                apt update
                apt install python3-pip apt-transport-https ca-certificates curl software-properties-common -y
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
                add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
                apt update && apt upgrade -y
                apt install docker-ce -y
                systemctl status docker
                usermod -aG docker ubuntu
                docker run -p 80:80 -d nginxdemos/hello
                EOF

  tags = {
    Name    = "EC2 multiple en ${aws_subnet.public[count.index].availability_zone}"
    Episodio = "Informe Nube 4"
  }

  depends_on = [aws_vpc.informe_nube, aws_key_pair.devago, aws_security_group.servidor_web]
}

resource "aws_eip_association" "multiple" {
  count         = length(data.aws_availability_zones.available.zone_ids)
  instance_id   = aws_instance.multiple[count.index].id
  allocation_id = aws_eip.multiple[count.index].id
}

output "multiple_dns" {
  value = aws_eip.multiple[*].public_dns
}