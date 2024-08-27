data "aws_route53_zone" "zone" { # Used to get data that exists in aws
  name = "${var.dns_zone_name}."
}

resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.zone.id
  name    = "${lookup(var.subdomain, terraform.workspace)}.${data.aws_route53_zone.zone.name}"
  type    = "CNAME"
  ttl     = "300"

  records = [aws_lb.api.dns_name]
}