provider "aws" {
  region = "eu-west-3"
}
data "aws_route53_zone" "selected" {
  name         = "biblioteca.tech."
  private_zone = false
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "www.${data.aws_route53_zone.selected.name}"
  type    = "A"
  ttl     = "300"
  records = ["10.0.0.1"]
}
