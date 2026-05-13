# ── VPC seleccionada ──────────────────────────────────────────────────────────
output "vpc_id" {
  value = data.aws_vpc.selected.id
}
output "vpc_cidr" {
  value = data.aws_vpc.selected.cidr_block
}

# ── Listados de VPCs (estrategias 4 y 5) ─────────────────────────────────────
output "all_vpc_ids" {
  value = data.aws_vpcs.all.ids
}
output "vpcs_by_env_tag_ids" {
  value = data.aws_vpcs.by_env_tag.ids
}

# ── Subredes ──────────────────────────────────────────────────────────────────
output "subnets_all_ids" {
  value = data.aws_subnets.all.ids
}
output "subnets_by_az_ids" {
  value = data.aws_subnets.by_az.ids
}
output "subnets_public_ids" {
  value = data.aws_subnets.public.ids
}
output "subnet_target_id" {
  value = data.aws_subnet.target.id
}
output "subnet_target_cidr" {
  value = data.aws_subnet.target.cidr_block
}

# ── AMI e instancia ───────────────────────────────────────────────────────────
output "ami_id" {
  value = data.aws_ami.ubuntu.id
}
output "ip_instance" {
  value = aws_instance.web.public_ip
}
output "ssh" {
  value = "ssh -l ubuntu ${aws_instance.web.public_ip}"
}