resource "aws_key_pair" "example" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

output "key_pair_name" {
  description = "Nombre de la key pair registrada en AWS"
  value       = aws_key_pair.example.key_name
}

output "key_pair_id" {
  description = "ID de la key pair"
  value       = aws_key_pair.example.id
}