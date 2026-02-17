terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "button-game-terraform-state-prod"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "button-game-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "ButtonGame"
      Environment = "prod"
      ManagedBy   = "Terraform"
    }
  }
}

locals {
  environment = "prod"
  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}

# Networking Module
module "networking" {
  source = "../../modules/networking"
  
  project_name = var.project_name
  environment  = local.environment
  vpc_cidr     = "10.0.0.0/16"
  tags         = local.common_tags
}

# Database Module  
module "database" {
  source = "../../modules/database"
  
  project_name          = var.project_name
  environment           = local.environment
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  rds_security_group_id = module.networking.rds_security_group_id
  
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  multi_az             = true  # Production uses Multi-AZ
  
  backup_retention_period = 7
  deletion_protection     = true  # Protect production DB
  
  tags = local.common_tags
}

# Elastic Beanstalk Module
module "elasticbeanstalk" {
  source = "../../modules/elasticbeanstalk"
  
  project_name           = var.project_name
  environment            = local.environment
  vpc_id                 = module.networking.vpc_id
  public_subnet_ids      = module.networking.public_subnet_ids
  alb_security_group_id  = module.networking.alb_security_group_id
  ec2_security_group_id  = module.networking.ec2_security_group_id
  
  instance_type = var.instance_type
  min_instances = var.min_instances
  max_instances = var.max_instances
  
  # Environment variables
  django_secret_key     = var.django_secret_key
  db_host               = module.database.db_endpoint
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  stripe_public_key     = var.stripe_public_key
  stripe_secret_key     = var.stripe_secret_key
  stripe_webhook_secret = var.stripe_webhook_secret
  allowed_hosts         = var.allowed_hosts
  
  enable_ssl            = var.enable_ssl
  ssl_certificate_arn   = var.enable_ssl ? module.dns[0].certificate_arn : null
  
  tags = local.common_tags
}

# DNS Module (if SSL enabled)
module "dns" {
  count  = var.enable_ssl ? 1 : 0
  source = "../../modules/dns"
  
  project_name         = var.project_name
  environment          = local.environment
  domain_name          = var.domain_name
  subdomain            = var.subdomain
  eb_cname             = module.elasticbeanstalk.cname
  
  tags = local.common_tags
}

# Data sources
data "aws_caller_identity" "current" {}
