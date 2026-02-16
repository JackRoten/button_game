# AWS Deployment Guide

This guide will walk you through deploying the Button Game application to AWS using Terraform and GitHub Actions.

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Domain name** registered (can be in Route53 or external registrar)
3. **GitHub repository** for the code
4. **Terraform** installed locally (>= 1.0)
5. **AWS CLI** installed and configured
6. **Stripe account** with live API keys

## Part 1: Initial AWS Setup

### 1.1 Configure AWS CLI

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (e.g., us-east-1)
# Enter your default output format (json)
```

### 1.2 Create Route53 Hosted Zone (if needed)

If your domain is not already in Route53:

```bash
aws route53 create-hosted-zone \
  --name yourdomain.com \
  --caller-reference $(date +%s)
```

Note the nameservers and update your domain registrar to point to them.

## Part 2: Terraform Infrastructure Setup

### 2.1 Prepare Terraform Variables

1. Navigate to the terraform directory:
   ```bash
   cd terraform
   ```

2. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit `terraform.tfvars` with your values:
   ```hcl
   aws_region  = "us-east-1"
   environment = "prod"
   domain_name = "yourdomain.com"
   subdomain   = "app"
   
   # Generate secure passwords
   db_username = "buttongame_admin"
   db_password = "<SECURE-PASSWORD-HERE>"
   django_secret_key = "<LONG-RANDOM-STRING>"
   
   # Stripe Live Keys
   stripe_public_key = "pk_live_..."
   stripe_secret_key = "sk_live_..."
   stripe_webhook_secret = "whsec_..."
   
   # Instance configuration
   instance_type = "t3.small"
   min_instances = 1
   max_instances = 4
   
   db_instance_class = "db.t3.micro"
   db_allocated_storage = 20
   
   enable_ssl = true
   ```

### 2.2 Generate Secure Secrets

Generate a Django secret key:
```bash
python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
```

Generate a secure database password:
```bash
openssl rand -base64 32
```

### 2.3 Initialize and Apply Terraform

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the infrastructure
terraform apply
```

This will create:
- VPC with public and private subnets
- RDS PostgreSQL database
- Elastic Beanstalk application and environment
- S3 buckets for static files and deployments
- CloudFront distribution
- ACM certificate for SSL
- Route53 DNS records
- IAM roles and policies
- Security groups

**Note**: This process takes 15-30 minutes, especially SSL certificate validation.

### 2.4 Save Terraform Outputs

```bash
terraform output > outputs.txt
```

Important outputs:
- `elastic_beanstalk_application_name`
- `elastic_beanstalk_environment_name`
- `s3_static_bucket`
- `application_url`

## Part 3: GitHub Actions Setup

### 3.1 Create GitHub Repository Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Create these secrets:

1. **AWS_ACCESS_KEY_ID**: Your AWS access key
2. **AWS_SECRET_ACCESS_KEY**: Your AWS secret key
3. **EB_S3_BUCKET**: The S3 bucket name from Terraform output (for deployment packages)

### 3.2 Update GitHub Actions Workflow

Edit `.github/workflows/deploy.yml`:

Update these values with your Terraform outputs:
```yaml
env:
  AWS_REGION: us-east-1  # Your region
  EB_APPLICATION_NAME: <from terraform output>
  EB_ENVIRONMENT_NAME: <from terraform output>
```

### 3.3 Push to GitHub

```bash
git add .
git commit -m "Initial deployment setup"
git push origin main
```

The GitHub Actions workflow will automatically:
1. Run tests
2. Build deployment package
3. Upload to S3
4. Deploy to Elastic Beanstalk

## Part 4: Post-Deployment Configuration

### 4.1 Verify Deployment

Visit your application URL:
```
https://app.yourdomain.com
```

### 4.2 Create Initial Superuser

SSH into your EB instance or use the following environment variables in EB configuration:

```bash
DJANGO_SUPERUSER_USERNAME=admin
DJANGO_SUPERUSER_EMAIL=admin@yourdomain.com
DJANGO_SUPERUSER_PASSWORD=<secure-password>
```

Then trigger a redeploy to create the superuser.

### 4.3 Configure Stripe Webhooks

1. Go to Stripe Dashboard → Developers → Webhooks
2. Add endpoint: `https://app.yourdomain.com/payment/webhook/`
3. Select events: `checkout.session.completed`
4. Copy the webhook signing secret
5. Update your Terraform variables or EB environment with the new secret

### 4.4 Test the Application

1. Create a test user account
2. Play the game
3. Test premium upgrade
4. Verify payment flow
5. Check leaderboard

## Part 5: Monitoring and Maintenance

### 5.1 CloudWatch Logs

View application logs:
```bash
aws elasticbeanstalk describe-environment-health \
  --environment-name <your-env-name> \
  --attribute-names All
```

Or access via AWS Console:
- CloudWatch → Log Groups → `/aws/elasticbeanstalk/<app-name>`

### 5.2 RDS Backups

Automated backups are configured (7-day retention). To create manual snapshot:

```bash
aws rds create-db-snapshot \
  --db-instance-identifier button-game-db-prod \
  --db-snapshot-identifier manual-snapshot-$(date +%Y%m%d)
```

### 5.3 Application Updates

To deploy updates:
```bash
git add .
git commit -m "Your changes"
git push origin main
```

GitHub Actions will automatically deploy.

### 5.4 Database Migrations

Migrations run automatically on deployment via `.ebextensions/02_python.config`

To run manual migration:
```bash
eb ssh
source /var/app/venv/*/bin/activate
cd /var/app/current
python manage.py migrate
```

## Part 6: Cost Optimization

### Current Monthly Costs (Estimated)

- **EC2 (t3.small)**: ~$15/month
- **RDS (db.t3.micro)**: ~$15/month
- **ALB**: ~$16/month
- **Data Transfer**: ~$5-10/month
- **S3/CloudFront**: ~$1-5/month
- **Route53**: ~$0.50/month

**Total**: ~$50-60/month

### Cost Reduction Options

1. **Use smaller instances**: t3.micro instead of t3.small
2. **Reserved Instances**: Save 30-40% with 1-year commitment
3. **Auto-scaling**: Scale down to 1 instance during low traffic
4. **RDS**: Use Aurora Serverless for variable workloads

## Part 7: Scaling

### Horizontal Scaling

Adjust auto-scaling in Terraform:
```hcl
min_instances = 2
max_instances = 10
```

### Vertical Scaling

Increase instance size:
```hcl
instance_type = "t3.medium"  # or larger
db_instance_class = "db.t3.small"  # or larger
```

## Part 8: Disaster Recovery

### Backup Strategy

1. **Database**: Automated daily backups (7-day retention)
2. **Application**: Git repository + Docker images
3. **Static files**: S3 versioning enabled
4. **Configuration**: Terraform state in S3 (recommended)

### Recovery Procedure

1. Restore RDS from snapshot
2. Redeploy application via GitHub Actions
3. Update DNS if needed

## Part 9: Security Checklist

- [ ] HTTPS enabled (SSL certificate)
- [ ] Database not publicly accessible
- [ ] Security groups properly configured
- [ ] Django DEBUG=False in production
- [ ] Secure secrets (not in code)
- [ ] CSRF protection enabled
- [ ] Regular security updates
- [ ] CloudWatch alarms configured
- [ ] IAM least privilege access
- [ ] Stripe webhook signature verification

## Part 10: Troubleshooting

### Deployment Failed

Check logs:
```bash
eb logs
# or
aws elasticbeanstalk request-environment-info \
  --environment-name <env-name> \
  --info-type tail
```

### Database Connection Issues

Verify security groups allow EC2 → RDS on port 5432

### Static Files Not Loading

Run collectstatic:
```bash
python manage.py collectstatic --noinput
```

### SSL Certificate Not Validating

Check DNS validation records in Route53

## Support Resources

- [AWS Elastic Beanstalk Documentation](https://docs.aws.amazon.com/elasticbeanstalk/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Django Deployment Checklist](https://docs.djangoproject.com/en/stable/howto/deployment/checklist/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## Next Steps

After successful deployment:

1. Set up monitoring and alerts
2. Configure CDN caching rules
3. Implement log aggregation
4. Set up staging environment
5. Configure backup automation
6. Plan scaling strategy
