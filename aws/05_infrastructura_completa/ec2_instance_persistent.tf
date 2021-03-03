# Elastic IPS
resource "aws_eip" "persistent" {
  vpc = true

  tags = {
    Name    = "IP elastica"
    Episodio = "Informe Nube 4"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_efs_file_system" "persistent" {
  creation_token = "InformeNube4"
  encrypted = true
  performance_mode = "generalPurpose"

  tags = {
    Name    = "EFS"
    Episodio = "Informe Nube 4"
  }
}

resource "aws_efs_mount_target" "persistent" {
  count           = length(data.aws_availability_zones.available.zone_ids)
  file_system_id  = aws_efs_file_system.persistent.id
  subnet_id       = element(aws_subnet.privada.*.id,count.index)
  security_groups = [aws_security_group.efs.id]
}


resource "aws_instance" "persistent" {
  availability_zone      = "eu-west-1b"
  ami                    = "ami-022e8cc8f0d3c52fd"
  count                  = 1
  instance_type          = "t3a.small"
  subnet_id              = aws_subnet.public[1].id
  vpc_security_group_ids = concat([aws_security_group.servidor_web.id], [aws_security_group.efs.id], [aws_default_security_group.default.id])
  key_name               = aws_key_pair.devago.id

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = "10"
    delete_on_termination = true
  }

  user_data = <<-EOF
                #!/bin/bash
                # ---> Updating, upgrating and installing the base
                apt update
                apt install python3-pip apt-transport-https ca-certificates curl software-properties-common nfs-common -y
                mkdir /var/lib/docker
                echo "${aws_efs_file_system.persistent.dns_name}:/  /var/lib/docker    nfs4   nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 2" >> /etc/fstab
                mount -a
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
                add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
                apt update && apt upgrade -y
                apt install docker-ce -y
                systemctl status docker
                usermod -aG docker ubuntu
                docker run -p 80:80 -d nginxdemos/hello
                EOF

  tags = {
    Name    = "EC2 con persistencia en ${aws_subnet.public[count.index].availability_zone}"
    Episodio = "Informe Nube 4"
  }

  depends_on = [aws_efs_file_system.persistent, aws_efs_mount_target.persistent]
}

resource "aws_eip_association" "persistent" {
  instance_id   = aws_instance.persistent[0].id
  allocation_id = aws_eip.persistent.id
}

output "persistent_dns" {
  value = aws_eip.persistent.public_dns
}