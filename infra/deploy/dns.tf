data "aws_route53_zone" "zone" { # Used to get data that exists in aws
  name = "${var.dns_zone_name}."
}

resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${lookup(var.subdomain, terraform.workspace)}.${data.aws_route53_zone.zone.name}"
  type    = "CNAME"
  ttl     = "300"

  records = [aws_lb.api.dns_name]
}

resource "aws_acm_certificate" "cert" { # AWS acm certificate cert resource
  domain_name       = aws_route53_record.app.name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" { # Doing a for loop, creating a record for each of these dynamic options
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true                               # wwe might want to overwrite these values if we want to validate nultiple times
  name            = each.value.name                    # pulls it from line 26
  records         = [each.value.record]                # Pulls from line 27
  ttl             = 60                                 # How long before it refreshes
  type            = each.value.type                    # Whatever record type we need, from line 28
  zone_id         = data.aws_route53_zone.zone.zone_id # Same zone from domain name we created
}

resource "aws_acm_certificate_validation" "cert" { # Actually running the validation for each certificate
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}