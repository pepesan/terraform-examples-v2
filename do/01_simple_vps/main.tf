variable "do_token" {}
variable "ssh_pub_path"{}
variable "droplet_image" {}

provider "digitalocean" {
    token = var.do_token
}

# Create a new SSH key
resource "digitalocean_ssh_key" "web-ssh" {
    name       = "Terraform Example"
    public_key = file(var.ssh_pub_path)
}



resource "digitalocean_droplet" "web" {
    name  = "tf-do"
    image = var.droplet_image
    region = "fra1"
    size   = "512mb"
    ssh_keys = [digitalocean_ssh_key.web-ssh.fingerprint]
}
 
output "ip" {
    value = digitalocean_droplet.web.ipv4_address
}
 
