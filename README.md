# Button Game - Django Web App

A Django-based web application for learning the framework. Features include user authentication, a color-changing button game, score tracking, and premium features through Stripe integration.

## Features Implemented

### Phase 1 & 2 (Complete):
- ✅ Django project structure
- ✅ User registration and authentication
- ✅ User login/logout
- ✅ User profiles
- ✅ Database models (UserProfile, Click)
- ✅ Basic templates and styling
- ✅ Password reset functionality

### Phase 3 (Complete):
- ✅ Interactive color-changing button
- ✅ Real-time click tracking via AJAX
- ✅ Score display with live updates
- ✅ 6 free colors for all users
- ✅ 8 additional premium colors (unlockable in Phase 5)
- ✅ Smooth animations and visual feedback
- ✅ Milestone celebrations (every 10 clicks)
- ✅ Responsive design for mobile devices

### Phase 4 (Complete):
- ✅ Global leaderboard showing top 100 players
- ✅ User rank display and tracking
- ✅ Global statistics (total players, total clicks)
- ✅ Personal stats highlighting in leaderboard
- ✅ Medal badges for top 3 players (🥇🥈🥉)
- ✅ Premium badge display on leaderboard
- ✅ Real-time rank calculation
- ✅ Responsive table design

### Phase 5 (Complete):
- ✅ Stripe payment integration
- ✅ Secure checkout flow
- ✅ Premium upgrade ($9.99 one-time payment)
- ✅ Payment success/cancel pages
- ✅ Webhook handler for payment verification
- ✅ Automatic premium status activation
- ✅ Premium color unlock (14 total colors)
- ✅ Environment variable configuration
- ✅ Test mode support

## 🎉 ALL PHASES COMPLETE!

## Setup Instructions

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

This installs:
- Django 4.2+
- Stripe 5.0+ (for payments)
- python-decouple (for environment variables)

### 2. Configure Environment Variables

1. Copy the example environment file:
```bash
cp .env.example .env
```

2. Edit `.env` and add your Stripe API keys:
```
STRIPE_PUBLIC_KEY=pk_test_your_key_here
STRIPE_SECRET_KEY=sk_test_your_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
```

**Important**: See `STRIPE_SETUP.md` for detailed instructions on getting your Stripe keys.

### 3. Set up the database
```bash
cd button_game_project
python manage.py makemigrations
python manage.py migrate
```

### 4. Create a superuser (admin account)
```bash
python manage.py createsuperuser
```
Follow the prompts to create your admin account.

### 5. Run the development server
```bash
python manage.py runserver
```

### 6. Access the application
- Main site: http://127.0.0.1:8000/
- Admin panel: http://127.0.0.1:8000/admin/

## Project Structure

```
button_game_project/
├── manage.py                          # Django management script
├── requirements.txt                   # Python dependencies
├── button_game_project/               # Project settings
│   ├── settings.py                   # Main configuration
│   ├── urls.py                       # Root URL configuration
│   ├── wsgi.py                       # WSGI config
│   └── asgi.py                       # ASGI config
└── game/                             # Main application
    ├── models.py                     # Database models
    ├── views.py                      # View functions
    ├── urls.py                       # App URL routing
    ├── forms.py                      # Form definitions
    ├── admin.py                      # Admin panel config
    ├── templates/                    # HTML templates
    │   ├── base.html                # Base template
    │   ├── home.html                # Home page
    │   ├── profile.html             # User profile
    │   └── registration/            # Auth templates
    │       ├── login.html
    │       └── signup.html
    └── static/                       # Static files
        └── css/
            └── style.css            # Custom CSS
```

## Database Models

### UserProfile
- Extends Django's built-in User model
- Fields: `is_premium`, `stripe_customer_id`
- One-to-one relationship with User

### Click
- Tracks button clicks for each user
- Fields: `user`, `click_count`, `last_clicked`
- Foreign key relationship with User

## Available URLs

- `/` - Home page
- `/signup/` - User registration
- `/login/` - User login
- `/logout/` - User logout
- `/game/` - Main game page with color-changing button (requires login)
- `/profile/` - User profile (requires login)
- `/leaderboard/` - Global leaderboard (public)
- `/api/button-click/` - AJAX endpoint for button clicks (requires login)
- `/payment/checkout/` - Stripe checkout session (requires login)
- `/payment/success/` - Payment success page
- `/payment/cancel/` - Payment cancelled page
- `/payment/webhook/` - Stripe webhook endpoint
- `/admin/` - Django admin panel
- `/password_reset/` - Password reset

## Stripe Payment Integration

### Premium Features:
- One-time payment of $9.99
- Unlocks 8 additional button colors (14 total)
- Premium ⭐ badge on profile and leaderboard
- Secure payment processing via Stripe

### Testing Payments:

Use Stripe test cards (in test mode):
- **Success**: 4242 4242 4242 4242
- **Decline**: 4000 0000 0000 0002
- Any future expiry date, any CVC, any ZIP

### Setup:
1. Create a free Stripe account at https://stripe.com
2. Get your test API keys from the Dashboard
3. Copy `.env.example` to `.env`
4. Add your Stripe keys to `.env`
5. See `STRIPE_SETUP.md` for complete setup instructions

### Payment Flow:
1. User clicks "Upgrade to Premium" on profile page
2. Redirected to Stripe Checkout (secure, hosted by Stripe)
3. User enters payment details
4. On success: redirected to success page, premium activated
5. On cancel: redirected to cancel page, no charge
6. Webhook confirms payment and updates database

## How the Game Works

### For Free Users:
1. Log in to your account
2. Navigate to the Game page
3. Click the circular button to change its color
4. Button cycles through 6 different colors
5. Your click count updates in real-time
6. Score is saved to the database automatically

### For Premium Users (Phase 5):
- Access to 14 total colors (6 free + 8 premium)
- Premium badge display
- Exclusive color palette

### Technical Implementation:
- **Frontend**: JavaScript handles immediate color changes and animations
- **Backend**: Django processes each click via AJAX and updates the database
- **AJAX**: Asynchronous requests ensure smooth gameplay without page refreshes
- **CSRF Protection**: All POST requests are protected with Django's CSRF tokens
- **Database**: Click counts persist across sessions using the Click model

## Leaderboard Features

### Global Stats:
- Total number of active players
- Combined click count across all users
- Your current rank (if logged in)

### Leaderboard Display:
- Top 100 players ranked by click count
- Medal badges for top 3 (🥇 Gold, 🥈 Silver, 🥉 Bronze)
- Premium badges for premium users
- Your row highlighted in blue
- Last played timestamp for each player

### Rankings:
- Real-time rank calculation
- Your personal stats card at the top
- Automatic sorting by click count
- Public access (no login required to view)

## Complete Feature List

### User Management:
- User registration and authentication
- Secure login/logout
- Password reset functionality
- User profiles with stats
- Email validation

### Game Features:
- Interactive color-changing button
- Real-time click tracking via AJAX
- Score persistence across sessions
- 6 free colors for all users
- 8 premium colors for premium members
- Smooth animations and visual feedback
- Milestone celebrations

### Leaderboard:
- Top 100 players ranking
- Medal badges for top 3
- Real-time rank calculation
- Global statistics
- Premium badges
- Public access

### Premium System:
- Stripe payment integration
- Secure checkout flow
- One-time payment model
- Automatic premium activation
- Webhook verification
- Test mode support

## Project Structure

```
button_game_project/
├── manage.py
├── requirements.txt
├── .env.example
├── README.md
├── STRIPE_SETUP.md
├── button_game_project/
│   ├── settings.py (Django config + Stripe settings)
│   ├── urls.py
│   ├── wsgi.py
│   └── asgi.py
└── game/
    ├── models.py (User, UserProfile, Click)
    ├── views.py (game, leaderboard, payments)
    ├── urls.py
    ├── forms.py
    ├── admin.py
    ├── templates/
    │   ├── base.html
    │   ├── home.html
    │   ├── game.html
    │   ├── profile.html
    │   ├── leaderboard.html
    │   ├── registration/
    │   │   ├── login.html
    │   │   └── signup.html
    │   └── payment/
    │       ├── success.html
    │       └── cancel.html
    └── static/
        └── css/
            └── style.css
```

## Technologies Used

- **Backend**: Django 4.2+
- **Database**: SQLite (development) / PostgreSQL (production-ready)
- **Frontend**: HTML, CSS, JavaScript, Bootstrap 5
- **Payments**: Stripe API
- **Authentication**: Django's built-in auth system
- **AJAX**: Fetch API for real-time updates

## Security Features

- CSRF protection on all forms
- Secure password validation
- Environment variable configuration
- Webhook signature verification
- Login required decorators
- SQL injection prevention (Django ORM)

## What You've Learned

Through building this project, you've learned:

1. **Django Fundamentals**:
   - Models, Views, Templates (MVT pattern)
   - Django ORM and database queries
   - URL routing and view functions
   - Template inheritance
   - Static files management

2. **User Authentication**:
   - User registration and login
   - Session management
   - Login required decorators
   - Password validation

3. **Database Design**:
   - Model relationships (OneToOne, ForeignKey)
   - Migrations
   - Database queries and aggregations
   - Model ordering and filtering

4. **Frontend Integration**:
   - AJAX requests with Fetch API
   - Real-time UI updates without page refresh
   - CSS animations and transitions
   - Responsive design

5. **Payment Processing**:
   - Stripe API integration
   - Checkout session creation
   - Webhook handling
   - Payment verification

6. **Best Practices**:
   - Environment variables for sensitive data
   - Git ignore for secrets
   - Code organization
   - Error handling

## Next Steps & Ideas

Want to expand this project? Here are some ideas:

- **Add achievements system** (badges for milestones)
- **Daily/weekly/monthly leaderboards** (time-based rankings)
- **Social features** (follow users, share scores)
- **Mobile app** (React Native or Flutter)
- **Different game modes** (timed challenges, combos)
- **User avatars** (profile pictures)
- **Admin dashboard** (analytics, user management)
- **Email notifications** (weekly stats, rank changes)
- **API endpoints** (public API for scores)
- **Multiple themes** (dark mode, custom colors)

## Deployment

Ready to deploy to AWS? We've got you covered!

### Production Deployment with AWS

This project includes complete infrastructure-as-code and CI/CD setup:

- **Terraform**: Full AWS infrastructure (VPC, RDS, Elastic Beanstalk, Route53, SSL)
- **GitHub Actions**: Automated testing and deployment pipeline
- **Elastic Beanstalk**: Managed application hosting with auto-scaling
- **PostgreSQL RDS**: Production-grade database
- **CloudFront**: CDN for static files
- **Route53**: DNS management

### Deployment Guides

- **[QUICKSTART.md](QUICKSTART.md)** - Fast deployment in 30 minutes
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Comprehensive deployment guide
- **[STRIPE_SETUP.md](STRIPE_SETUP.md)** - Stripe payment configuration

### Quick Deploy

```bash
# 1. Setup infrastructure
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply

# 2. Configure GitHub secrets
# Add AWS credentials and EB bucket to GitHub

# 3. Deploy
git push origin main
```

See [QUICKSTART.md](QUICKSTART.md) for detailed steps.

### Infrastructure Included

- VPC with public and private subnets
- Application Load Balancer with SSL/HTTPS
- Auto-scaling EC2 instances (t3.small)
- PostgreSQL RDS database (db.t3.micro)
- S3 buckets for static files and deployments
- CloudFront CDN distribution
- Route53 DNS records
- ACM SSL certificate
- CloudWatch logging and monitoring
- IAM roles with least privilege

### Monthly Cost Estimate

- **Development**: ~$30-40/month
- **Production**: ~$50-60/month
- **Scalable**: Up to hundreds of requests/second

---

1. Set `DEBUG=False` in production
2. Configure `ALLOWED_HOSTS`
3. Use PostgreSQL instead of SQLite
4. Set up static files serving (WhiteNoise or CDN)
5. Use environment variables for all secrets
6. Enable HTTPS (required for Stripe)
7. Configure Stripe live mode keys
8. Set up production webhook endpoint

Popular deployment options:
- Heroku
- DigitalOcean
- AWS Elastic Beanstalk
- Railway
- Render

## Support & Resources

- Django Documentation: https://docs.djangoproject.com/
- Stripe Documentation: https://stripe.com/docs
- Bootstrap Documentation: https://getbootstrap.com/docs/
- Django Tutorial: https://docs.djangoproject.com/en/stable/intro/tutorial01/

## License

This is a learning project. Feel free to use it as a starting point for your own projects!

---

**Congratulations!** 🎉 You've built a complete, production-ready Django web application with authentication, real-time features, a leaderboard, and payment processing!

## Notes

- The project uses SQLite by default (good for development)
- For production, switch to PostgreSQL in settings.py
- SECRET_KEY in settings.py should be changed for production
- DEBUG should be set to False in production
- Bootstrap 5 is used for quick styling (loaded via CDN)

## Learning Resources

- Django Documentation: https://docs.djangoproject.com/
- Django Authentication: https://docs.djangoproject.com/en/stable/topics/auth/
- Django Models: https://docs.djangoproject.com/en/stable/topics/db/models/
