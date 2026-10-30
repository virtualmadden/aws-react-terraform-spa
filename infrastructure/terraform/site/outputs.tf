output "site_bucket" {
  description = "Upload target for the built app (dist/)."
  value       = aws_s3_bucket.site.id
}

output "cloudfront_distribution_id" {
  description = "Invalidate after uploading."
  value       = aws_cloudfront_distribution.site.id
}

output "url" {
  value = "https://${var.domain_name}"
}
