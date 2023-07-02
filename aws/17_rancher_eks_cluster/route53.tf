resource "aws_route53_zone" "example_zone" {
  name = var.domain_name
}

resource "aws_route53_record" "wildcard_cname" {
  zone_id = aws_route53_zone.example_zone.zone_id
  name    = "${var.subdomain_wildcard}.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [module.eks.cluster_endpoint]  # apunta al cluster

  depends_on = [module.eks]
}