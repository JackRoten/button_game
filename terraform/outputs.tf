output "elastic_beanstalk_environment_name" {
  description = "Elastic Beanstalk environment name"
  value       = aws_elastic_beanstalk_environment.main.name
}

output "elastic_beanstalk_application_name" {
  description = "Elastic Beanstalk application name"
  value       = aws_elastic_beanstalk_application.main.name
}

output "elastic_beanstalk_cname" {
  description = "Elastic Beanstalk CNAME"
  value       = aws_elastic_beanstalk_environment.main.cname
}

output "elastic_beanstalk_url" {
  description = "Elastic Beanstalk application URL"
  value       = "http://${aws_elastic_beanstalk_environment.main.cname}"
}

output "application_url" {
  description = "Application URL with custom domain"
  value       = var.enable_ssl ? "https://${var.subdomain}.${var.domain_name}" : "http://${var.subdomain}.${var.domain_name}"
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.main.db_name
}

output "s3_static_bucket" {
  description = "S3 bucket for static files"
  value       = aws_s3_bucket.static_files.bucket
}

output "s3_static_bucket_url" {
  description = "S3 bucket URL for static files"
  value       = "https://${aws_s3_bucket.static_files.bucket_regional_domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.static.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.static.domain_name
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "route53_nameservers" {
  description = "Route53 nameservers"
  value       = data.aws_route53_zone.main.name_servers
}
