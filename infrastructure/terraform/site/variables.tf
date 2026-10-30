variable "domain_name" {
  description = "Hostname the site serves, e.g. example.com or app.example.com."
  type        = string
}

variable "hosted_zone_name" {
  description = "Existing Route53 public hosted zone, in this account, that holds domain_name. Defaults to domain_name itself."
  type        = string
  default     = null
}

variable "include_www" {
  description = "Also serve www.<domain_name>. Usually true for an apex domain and false for a subdomain."
  type        = bool
  default     = true
}

variable "aws_region" {
  description = "Region for the S3 bucket. CloudFront and its certificate are global (us-east-1) regardless."
  type        = string
  default     = "us-west-2"
}

variable "price_class" {
  description = "CloudFront price class: PriceClass_100 (North America and Europe), PriceClass_200, or PriceClass_All."
  type        = string
  default     = "PriceClass_100"
}

variable "content_security_policy" {
  description = "Content-Security-Policy directives, joined into the header. The default allows only this site's own origin; loosen it if the app loads anything from elsewhere."
  type        = list(string)
  default = [
    "default-src 'none'",
    "script-src 'self'",
    "style-src 'self'",
    "img-src 'self' data:",
    "font-src 'self'",
    "connect-src 'self'",
    "manifest-src 'self'",
    "base-uri 'none'",
    "form-action 'self'",
    "frame-ancestors 'none'",
  ]
}

variable "tags" {
  description = "Extra tags for every resource."
  type        = map(string)
  default     = {}
}

locals {
  # coalesce also treats "" as unset, which is what an empty GitHub variable becomes.
  zone_name = coalesce(var.hosted_zone_name, var.domain_name)
  aliases   = var.include_www ? [var.domain_name, "www.${var.domain_name}"] : [var.domain_name]

  tags = merge({ Site = var.domain_name, ManagedBy = "terraform" }, var.tags)
}
