variable "do_token" {}
variable "ssh_pub_path"{}
variable "region" {}
variable "project_name" {}

provider "digitalocean" {
    token = var.do_token
}

# Create a new SSH key
resource "digitalocean_ssh_key" "web-ssh" {
    name       = "${var.project_name}-key"
    public_key = file(var.ssh_pub_path)
}


data "template_file" "userdata" {
    template = file("${path.module}/userdata.sh")
}

resource "digitalocean_droplet" "web" {
    name  = "${var.project_name}-web"
    image = "ubuntu-20-04-x64"
    region = var.region
    size   = "s-1vcpu-1gb"
    backups = true
    user_data = data.template_file.userdata.rendered
    ssh_keys = [digitalocean_ssh_key.web-ssh.fingerprint]
}

resource "digitalocean_volume" "web" {
    region                  = var.region
    name                    = "${var.project_name}-web-volume"
    size                    = 10
    initial_filesystem_type = "ext4"
    description             = "${var.project_name} web volume description"
}

resource "digitalocean_volume_attachment" "web" {
    droplet_id = digitalocean_droplet.web.id
    volume_id  = digitalocean_volume.web.id
}
 
output "ip" {
    value = digitalocean_droplet.web.ipv4_address
}
output "ssh" {
    value = "ssh -l root ${digitalocean_droplet.web.ipv4_address}"
}
output "ram" {
    value = digitalocean_droplet.web.size
}
output "vps-disk" {
    value = digitalocean_droplet.web.disk
}
output "volume_disk" {
    value = digitalocean_volume.web.size
}


 
