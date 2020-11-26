variable "do_token" {}
variable "ssh_pub_path"{}
variable "droplet_image" {}
variable "droplet_size" {}

provider "digitalocean" {
    token = var.do_token
}

# Create a new SSH key
resource "digitalocean_ssh_key" "web-ssh" {
    name       = "Terraform Example"
    public_key = file(var.ssh_pub_path)
}

data "template_file" "userdata" {
    template = file("${path.module}/userdata.sh")
}

resource "digitalocean_droplet" "web" {
    name  = "tf-do"
    image = var.droplet_image
    region = "fra1"
    size   = var.droplet_size
    user_data = data.template_file.userdata.rendered
    ssh_keys = [digitalocean_ssh_key.web-ssh.fingerprint]
}
 
output "ip" {
    value = digitalocean_droplet.web.ipv4_address
}
