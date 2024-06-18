# output "instance_ip" {
#   description = "The public ip for the instance"
#   value = aws_instance.web
# }
output "instance_public_ips" {
  description = "Las IPs públicas de las instancias web"
  value       = aws_instance.web[*].public_ip
}

output "ssh_commands" {
  description = "Comandos SSH para las instancias web"
  value = [
    for ip in aws_instance.web[*].public_ip : "ssh -l ubuntu ${ip}"
  ]
}


# output "ssh" {
#   value = "ssh -l ubuntu ${aws_instance.web.*.public_ip}"
# }
# output "url" {
#   value = "https://${aws_instance.web.*.public_ip}/"
# }