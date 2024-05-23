provider "aws" {
  region = "eu-west-3"
}
data "aws_route53_zone" "selected" {
  name         = "buildconfes.click."
  private_zone = false
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "www.${data.aws_route53_zone.selected.name}"
  type    = "A"
  ttl     = "300"
  records = ["10.0.0.1"]
}
resource "aws_route53_record" "ftp" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "ftp.${data.aws_route53_zone.selected.name}"
  type    = "A"
  ttl     = "300"
  records = ["10.0.0.1"]
}
resource "aws_route53_record" "ssh" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "ssh.${data.aws_route53_zone.selected.name}"
  type    = "A"
  ttl     = "300"
  records = ["207.188.178.150"]
}

