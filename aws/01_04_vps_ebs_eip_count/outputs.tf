# output "instance_ip" {
#   description = "The public ip for the instance"
#   value = aws_instance.web
# }


# output "ssh" {
#   value = "ssh -l ubuntu ${aws_instance.web.*.public_ip}"
# }
# output "url" {
#   value = "https://${aws_instance.web.*.public_ip}/"
# }