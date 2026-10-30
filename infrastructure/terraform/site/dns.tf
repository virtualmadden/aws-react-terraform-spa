# The zone is the one thing this stack assumes already exists: it's tied to the domain's
# registration and delegation, which outlive any one site.
data "aws_route53_zone" "this" {
  name         = local.zone_name
  private_zone = false
}

resource "aws_route53_record" "site" {
  for_each = toset(flatten([for name in local.aliases : [for type in ["A", "AAAA"] : "${name}/${type}"]]))

  zone_id = data.aws_route53_zone.this.zone_id
  name    = split("/", each.key)[0]
  type    = split("/", each.key)[1]

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}
