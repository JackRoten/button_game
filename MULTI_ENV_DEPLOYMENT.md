# Multi-Environment Deployment Guide

This guide explains how to deploy the Button Game application to both **Gamma (Staging)** and **Production** environments using Terraform and GitHub Actions.

## Architecture Overview

```
┌─────────────────────────────────────────┐
│         GitHub Repository               │
│                                         │
│  main branch    →  Production (prod)   │
│  gamma branch   →  Staging (gamma)     │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│        GitHub Actions CI/CD             │
│                                         │
│  1. Test (PostgreSQL)                  │
│  2. Build deployment package           │
│  3. Deploy to environment              │
└─────────────────────────────────────────┘
                    ↓
┌──────────────┬──────────────────────────┐
│    Gamma     │      Production          │
├──────────────┼──────────────────────────┤
│ gamma.       │  app.yourdomain.com      │
│ yourdomain   │                          │
│ .com         │                          │
├──────────────┼──────────────────────────┤
│ t3.micro     │  t3.small (2+ instances) │
│ 1 instance   │  Multi-AZ RDS            │
│ Single-AZ    │  Deletion protection     │
│ RDS          │                          │
│              │                          │
│ Test Stripe  │  Live Stripe keys        │
│ keys         │                          │
└──────────────┴──────────────────────────┘
```

## Environment Differences

| Feature | Gamma (Staging) | Production |
|---------|----------------|------------|
| **Domain** | gamma.yourdomain.com | app.yourdomain.com |
| **Instance Type** | t3.micro | t3.small |
| **Min Instances** | 1 | 2 |
| **Max Instances** | 2 | 6 |
| **RDS Instance** | db.t3.micro | db.t3.small |
| **Multi-AZ** | No | Yes |
| **Deletion Protection** | No | Yes |
| **Backup Retention** | 3 days | 7 days |
| **Stripe Keys** | Test mode | Live mode |
| **Cost/Month** | ~$25-30 | ~$60-80 |

## Step 1: Infrastructure Setup

### 1.1 Deploy Gamma Environment

```bash
cd terraform/environments/gamma

# Copy and configure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with gamma-specific values

# Initialize
terraform init

# Plan and apply
terraform plan -out=gamma.tfplan
terraform apply gamma.tfplan

# Save outputs
terraform output > gamma-outputs.txt
```

### 1.2 Deploy Production Environment

```bash
cd terraform/environments/prod

# Copy and configure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with production values

# Initialize
terraform init

# Plan and apply
terraform plan -out=prod.tfplan
terraform apply prod.tfplan

# Save outputs
terraform output > prod-outputs.txt
```

## Step 2: GitHub Configuration

### 2.1 Create GitHub Secrets

Go to GitHub → Settings → Secrets and variables → Actions

**Environment-agnostic secrets:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

**Gamma-specific secrets:**
- `GAMMA_EB_APP_NAME` (from terraform output)
- `GAMMA_EB_ENV_NAME` (from terraform output)
- `GAMMA_S3_BUCKET` (from terraform output)

**Production-specific secrets:**
- `PROD_EB_APP_NAME` (from terraform output)
- `PROD_EB_ENV_NAME` (from terraform output)
- `PROD_S3_BUCKET` (from terraform output)

### 2.2 Create GitHub Environments

1. Go to Settings → Environments
2. Create `gamma` environment
3. Create `production` environment
   - Add protection rules (require approvals for prod)
   - Add reviewers (recommended)

## Step 3: Branch Strategy

### Create Branches

```bash
# Create gamma branch
git checkout -b gamma
git push origin gamma

# Create main branch (if not exists)
git checkout -b main
git push origin main
```

### Branch Flow

```
Feature Branch → gamma branch → test & deploy to Gamma
                      ↓
                 (after testing)
                      ↓
                 main branch → deploy to Production
```

## Step 4: Deployment Workflow

### Deploy to Gamma (Staging)

```bash
# Make changes
git checkout gamma
git add .
git commit -m "Feature: add new functionality"
git push origin gamma
```

GitHub Actions will:
1. Run tests
2. Build deployment package
3. Deploy to gamma environment
4. URL: https://gamma.yourdomain.com

### Promote to Production

After testing in gamma:

```bash
# Merge to main
git checkout main
git merge gamma
git push origin main
```

GitHub Actions will:
1. Run tests
2. Build deployment package
3. Deploy to production (with approval if configured)
4. URL: https://app.yourdomain.com

### Manual Deployment

Use workflow dispatch:
1. Go to Actions → Multi-Environment CI/CD
2. Click "Run workflow"
3. Select branch and environment
4. Click "Run workflow"

## Step 5: Configuration Management

### Environment Variables by Environment

**Gamma** (`.env.gamma`):
```bash
DEBUG=False
STRIPE_PUBLIC_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
ALLOWED_HOSTS=gamma.yourdomain.com
```

**Production** (`.env.prod`):
```bash
DEBUG=False
STRIPE_PUBLIC_KEY=pk_live_...
STRIPE_SECRET_KEY=sk_live_...
ALLOWED_HOSTS=app.yourdomain.com
```

These are configured in Terraform and passed to Elastic Beanstalk.

## Step 6: Database Migrations

Migrations run automatically on deployment via `.ebextensions/02_python.config`

### Manual Migration

**Gamma:**
```bash
eb ssh button-game-env-gamma
source /var/app/venv/*/bin/activate
cd /var/app/current
python manage.py migrate
```

**Production:**
```bash
eb ssh button-game-env-prod
source /var/app/venv/*/bin/activate
cd /var/app/current
python manage.py migrate
```

## Step 7: Monitoring

### CloudWatch Logs

**Gamma:**
```bash
aws logs tail /aws/elasticbeanstalk/button-game-gamma --follow
```

**Production:**
```bash
aws logs tail /aws/elasticbeanstalk/button-game-prod --follow
```

### Health Checks

**Gamma:**
```bash
aws elasticbeanstalk describe-environment-health \
  --environment-name button-game-env-gamma \
  --attribute-names All
```

**Production:**
```bash
aws elasticbeanstalk describe-environment-health \
  --environment-name button-game-env-prod \
  --attribute-names All
```

## Step 8: Rollback

### Rollback to Previous Version

**Via AWS CLI:**
```bash
# List versions
aws elasticbeanstalk describe-application-versions \
  --application-name button-game-prod

# Deploy previous version
aws elasticbeanstalk update-environment \
  --environment-name button-game-env-prod \
  --version-label <previous-version-label>
```

**Via Console:**
1. Go to Elastic Beanstalk console
2. Select environment
3. Click "Application versions"
4. Select previous version
5. Click "Deploy"

## Step 9: Disaster Recovery

### Database Backups

**Restore from automated backup:**
```bash
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier button-game-db-prod-restored \
  --db-snapshot-identifier <snapshot-id>
```

**Create manual snapshot:**
```bash
aws rds create-db-snapshot \
  --db-instance-identifier button-game-db-prod \
  --db-snapshot-identifier manual-$(date +%Y%m%d)
```

## Step 10: Cost Management

### Current Costs

**Gamma (Staging):**
- EC2 t3.micro: $7/month
- RDS db.t3.micro (single-AZ): $12/month
- ALB: $16/month
- Other: $5/month
- **Total: ~$40/month**

**Production:**
- EC2 t3.small (2 instances): $30/month
- RDS db.t3.small (Multi-AZ): $30/month
- ALB: $16/month
- Other: $10/month
- **Total: ~$86/month**

### Cost Optimization

**For Gamma:**
- Stop environment during off-hours (save 60%)
- Use db.t3.micro
- Single instance

**For Production:**
- Use Reserved Instances (save 30-40%)
- Auto-scale based on traffic
- Consider Spot Instances for non-critical loads

## Troubleshooting

### Deployment Failed

1. Check GitHub Actions logs
2. Check CloudWatch logs
3. Verify environment variables
4. Check security group rules

### Database Connection Failed

```bash
# Test from EC2
telnet <db-endpoint> 5432

# Check security groups
aws ec2 describe-security-groups \
  --group-ids <rds-sg-id>
```

### SSL Certificate Not Working

```bash
# Check certificate status
aws acm describe-certificate \
  --certificate-arn <cert-arn>

# Verify DNS records
dig gamma.yourdomain.com
dig app.yourdomain.com
```

## Best Practices

1. **Always test in Gamma first**
2. **Use pull requests** for code review
3. **Tag releases** in production
4. **Monitor logs** after deployment
5. **Have rollback plan** ready
6. **Database backups** before major changes
7. **Test Stripe webhooks** in both environments
8. **Document environment differences**
9. **Use environment protection** rules
10. **Regular security updates**

## Quick Commands

```bash
# Deploy to gamma
git push origin gamma

# Deploy to production
git checkout main
git merge gamma
git push origin main

# View gamma logs
aws logs tail /aws/elasticbeanstalk/button-game-gamma --follow

# View prod logs
aws logs tail /aws/elasticbeanstalk/button-game-prod --follow

# Gamma health
aws elasticbeanstalk describe-environment-health \
  --environment-name button-game-env-gamma --attribute-names All

# Prod health
aws elasticbeanstalk describe-environment-health \
  --environment-name button-game-env-prod --attribute-names All
```

## Support

For issues, check:
1. GitHub Actions workflow runs
2. CloudWatch logs
3. Elastic Beanstalk events
4. RDS monitoring

## Next Steps

- Set up alerts and monitoring
- Configure backup automation
- Implement blue-green deployments
- Add performance testing
- Set up APM (Application Performance Monitoring)
