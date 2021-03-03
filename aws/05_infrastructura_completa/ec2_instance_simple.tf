# Elastic IPS
resource "aws_eip" "simple" {
  vpc = true

  tags = {
    Name    = "IP elastica"
    Episodio = "Informe Nube 4"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_instance" "simple" {
  count                       = 1
  availability_zone           = "eu-west-1a"
  ami                         = "ami-022e8cc8f0d3c52fd" // AMI son regionales (distintas IDS por region)
  instance_type               = "t3a.small"
  subnet_id                   = aws_subnet.public[0].id
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
    Name    = "EC2 simple en ${aws_subnet.public[count.index].availability_zone}"
    Episodio = "Informe Nube 4"
  }

  depends_on = [aws_vpc.informe_nube, aws_key_pair.devago, aws_security_group.servidor_web]
}

resource "aws_eip_association" "simple" {
  instance_id   = aws_instance.simple[0].id
  allocation_id = aws_eip.simple.id
}

output "simple_dns" {
  value = aws_eip.simple.public_dns
}