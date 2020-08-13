variable "do_token" {}
variable "ssh_pub_path"{}
variable "region" {}
variable "project_name" {}
variable "docker_cmd" {}
variable "hostname-prefix" {}
variable "droplet_size" {}
variable "instance_type" {}
variable "node_count" {}
variable "domain_name" {}
variable "rancher_dns_name" {}

provider "digitalocean" {
    token = var.do_token
}

# Create a new SSH key
resource "digitalocean_ssh_key" "web-ssh" {
    name       = "${var.project_name}-key"
    public_key = file(var.ssh_pub_path)
}



data "template_file" "userdata" {
    template = templatefile("${path.module}/userdata.sh", {
        "hostname-prefix" = var.hostname-prefix,
        "docker_cmd" = var.docker_cmd,
        "dns_name" = "rancher.${var.domain_name}"
    })
}
# consulta del dominio en DO
resource "digitalocean_domain" "biblioteca-tech" {
    name = "biblioteca.tech"
}
# creación del registro dns A para el servidor
resource "digitalocean_record" "rancher" {
    domain = digitalocean_domain.biblioteca-tech.name
    type   = "A"
    name   = var.rancher_dns_name
    value  = digitalocean_droplet.web.ipv4_address
}

resource "digitalocean_droplet" "web" {
    image               = "ubuntu-20-04-x64"
    region              = var.region
    user_data           = data.template_file.userdata.rendered
    ssh_keys = [digitalocean_ssh_key.web-ssh.fingerprint]
    name               = "rancher-${var.instance_type}"
    size               = var.droplet_size
    backups            = true
    ipv6               = true
    private_networking = false

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
    value = "${digitalocean_droplet.web.ipv4_address}"
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

# Output the FQDN for the www A record.
output "rancher_fqdn" {
    value = digitalocean_record.rancher.fqdn
}


 
