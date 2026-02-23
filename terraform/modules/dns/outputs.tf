output "certificate_arn" {
  description = "ARN of the validated ACM certificate (passed to the EB module for the HTTPS listener)"
  value       = aws_acm_certificate_validation.main.certificate_arn
}

output "certificate_domain" {
  description = "Primary domain name of the ACM certificate"
  value       = aws_acm_certificate.main.domain_name
}

output "app_fqdn" {
  description = "Fully-qualified domain name of the application (subdomain.domain)"
  value       = aws_route53_record.app.fqdn
}

output "zone_id" {
  description = "Route53 hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}
