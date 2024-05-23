output "vpcs" {
  value = data.aws_vpcs.vpcs.ids
}

output "vpcs-ids" {
  value = data.aws_vpc.selected.id
}

output "subnets-ids" {
  value = data.aws_subnets.example.ids
}


