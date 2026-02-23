output "application_name" {
  description = "Elastic Beanstalk application name"
  value       = aws_elastic_beanstalk_application.main.name
}

output "environment_name" {
  description = "Elastic Beanstalk environment name"
  value       = aws_elastic_beanstalk_environment.main.name
}

output "cname" {
  description = "Elastic Beanstalk environment CNAME (used by the dns module for Route53)"
  value       = aws_elastic_beanstalk_environment.main.cname
}

output "endpoint_url" {
  description = "Elastic Beanstalk environment endpoint URL"
  value       = aws_elastic_beanstalk_environment.main.endpoint_url
}

output "eb_versions_bucket" {
  description = "S3 bucket name used for EB application versions"
  value       = aws_s3_bucket.eb_versions.bucket
}

output "ec2_instance_profile_name" {
  description = "IAM instance profile name attached to EB EC2 instances"
  value       = aws_iam_instance_profile.ec2.name
}
