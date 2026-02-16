# Quick Start Deployment Guide

## Prerequisites
- AWS account configured (`aws configure`)
- Domain name in Route53
- Terraform installed
- GitHub repository created

## 1. Infrastructure Setup (15-30 minutes)

```bash
cd terraform

# Copy and edit configuration
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Deploy infrastructure
terraform init
terraform plan
terraform apply
```

**Save outputs:**
```bash
terraform output > ../outputs.txt
```

## 2. GitHub Secrets Setup

Add to GitHub → Settings → Secrets:

1. `AWS_ACCESS_KEY_ID`
2. `AWS_SECRET_ACCESS_KEY`
3. `EB_S3_BUCKET` (from terraform output)

## 3. Update GitHub Workflow

Edit `.github/workflows/deploy.yml`:

```yaml
env:
  EB_APPLICATION_NAME: <from terraform output>
  EB_ENVIRONMENT_NAME: <from terraform output>
```

## 4. Deploy Application

```bash
git add .
git commit -m "Production deployment"
git push origin main
```

GitHub Actions will automatically deploy!

## 5. Verify Deployment

Visit: `https://app.yourdomain.com`

## 6. Configure Stripe Webhook

Stripe Dashboard → Webhooks → Add endpoint:
- URL: `https://app.yourdomain.com/payment/webhook/`
- Events: `checkout.session.completed`

Update webhook secret in Terraform vars and redeploy.

## Common Commands

### View Logs
```bash
aws logs tail /aws/elasticbeanstalk/<app-name> --follow
```

### SSH to Instance
```bash
eb ssh <environment-name>
```

### Manual Deployment
```bash
# Create deployment package
zip -r deploy.zip . -x '*.git*' 'terraform/*' 'venv/*'

# Upload and deploy
aws elasticbeanstalk create-application-version \
  --application-name <app-name> \
  --version-label v1 \
  --source-bundle S3Bucket=<bucket>,S3Key=deploy.zip

aws elasticbeanstalk update-environment \
  --environment-name <env-name> \
  --version-label v1
```

### Database Migration
```bash
eb ssh
source /var/app/venv/*/bin/activate
cd /var/app/current
python manage.py migrate
```

### Destroy Infrastructure
```bash
cd terraform
terraform destroy
```

## Costs
- **Monthly**: ~$50-60
- **Breakdown**: EC2 ($15) + RDS ($15) + ALB ($16) + Other ($10)

## Troubleshooting

**Deployment failed?**
- Check GitHub Actions logs
- Check CloudWatch logs
- Verify environment variables

**SSL not working?**
- Wait for certificate validation (can take 30+ min)
- Verify DNS records in Route53

**Database connection failed?**
- Check security group rules
- Verify RDS credentials

## Support
See DEPLOYMENT.md for detailed documentation.
