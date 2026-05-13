output "vpcs" {
  value = data.aws_vpcs.vpcs.ids
}

output "vpc-ids" {
  value = data.aws_vpc.selected.id
}

output "vpcs-cidr_block" {
  value = data.aws_vpc.selected.cidr_block
}

output "subnets-ids" {
  value = data.aws_subnets.example.ids
}

output "ami_id" {
  value = data.aws_ami.ubuntu.id
}

output "ip_instance" {
  value = aws_instance.web.public_ip
}

output "ssh" {
  value = "ssh -l ubuntu ${aws_instance.web.public_ip}"
}



