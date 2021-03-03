# SSH Keys
resource "aws_key_pair" "devago" {
  key_name   = "devago"
  public_key = file(var.ssh_pub_path)

  tags = {
    Name     = "devago"
    Usuario  = "Antony R. Goetzschel <ago>"
    Episodio = "Informe Nube 4"
  }
}