variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. gamma, prod)"
  type        = string
}

variable "domain_name" {
  description = "Root domain name (must have an existing Route53 hosted zone)"
  type        = string
}

variable "subdomain" {
  description = "Subdomain to create (e.g. 'app' creates app.<domain_name>)"
  type        = string
  default     = "app"
}

variable "eb_cname" {
  description = "Elastic Beanstalk environment CNAME to point the subdomain at"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
