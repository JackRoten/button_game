# Stripe Integration Setup Guide

This guide will walk you through setting up Stripe payments for the Button Game premium feature.

## Step 1: Create a Stripe Account

1. Go to https://stripe.com and sign up for a free account
2. Complete the account verification process
3. You'll start in "Test Mode" which is perfect for development

## Step 2: Get Your API Keys

1. Log in to your Stripe Dashboard: https://dashboard.stripe.com/
2. Make sure you're in **Test Mode** (toggle in the top right)
3. Go to **Developers** → **API Keys**
4. You'll see two keys:
   - **Publishable key** (starts with `pk_test_`)
   - **Secret key** (starts with `sk_test_`)
5. Click "Reveal test key" to see your secret key

## Step 3: Configure Your Django Project

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and add your Stripe keys:
   ```
   STRIPE_PUBLIC_KEY=pk_test_your_actual_key_here
   STRIPE_SECRET_KEY=sk_test_your_actual_key_here
   STRIPE_PREMIUM_PRICE=999
   ```

3. The `STRIPE_PREMIUM_PRICE` is in cents (999 = $9.99)

## Step 4: Install Dependencies

```bash
pip install -r requirements.txt
```

This will install:
- stripe (Stripe Python library)
- python-decouple (for environment variables)

## Step 5: Test the Payment Flow

1. Start your Django server:
   ```bash
   python manage.py runserver
   ```

2. Log in to your account and go to your profile

3. Click "Upgrade to Premium - $9.99"

4. You'll be redirected to Stripe Checkout

5. Use Stripe's test card numbers:
   - **Successful payment**: 4242 4242 4242 4242
   - **Declined payment**: 4000 0000 0000 0002
   - Use any future expiry date (e.g., 12/34)
   - Use any 3-digit CVC (e.g., 123)
   - Use any ZIP code (e.g., 12345)

6. Complete the payment and you'll be redirected back to the success page

7. Your account should now be Premium!

## Step 6: Set Up Webhooks (Optional but Recommended)

Webhooks ensure payment confirmations even if the user closes their browser.

### For Local Development:

1. Install Stripe CLI: https://stripe.com/docs/stripe-cli

2. Login to Stripe CLI:
   ```bash
   stripe login
   ```

3. Forward webhooks to your local server:
   ```bash
   stripe listen --forward-to localhost:8000/payment/webhook/
   ```

4. Copy the webhook signing secret (starts with `whsec_`)

5. Add it to your `.env` file:
   ```
   STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
   ```

### For Production:

1. Go to Stripe Dashboard → **Developers** → **Webhooks**
2. Click "Add endpoint"
3. Enter your webhook URL: `https://yourdomain.com/payment/webhook/`
4. Select events to listen to: `checkout.session.completed`
5. Copy the signing secret and add to your production environment variables

## Step 7: Going Live

When you're ready to accept real payments:

1. Complete Stripe account verification
2. Switch from Test Mode to Live Mode in Stripe Dashboard
3. Get your **Live** API keys (they start with `pk_live_` and `sk_live_`)
4. Update your production `.env` file with live keys
5. Set `DEBUG=False` in Django settings
6. Set up your production webhook endpoint

## Security Notes

- **Never commit your `.env` file to git** (it's already in `.gitignore`)
- **Never share your secret keys** publicly
- **Use environment variables** in production
- **Enable HTTPS** in production (required by Stripe)
- **Validate webhook signatures** (already implemented)

## Troubleshooting

### Payment not completing:
- Check your Stripe API keys are correct
- Ensure you're using test card numbers in test mode
- Check Django logs for errors

### Webhook not working:
- Verify webhook secret is correct
- Check that Stripe CLI is running (for local dev)
- Verify webhook endpoint is accessible
- Check webhook logs in Stripe Dashboard

### Premium status not updating:
- Check if webhook was received successfully
- Verify user_id is in session metadata
- Check Django logs for errors in webhook handler

## Testing Checklist

- [ ] Payment with valid card succeeds
- [ ] User redirected to success page
- [ ] Premium status activated
- [ ] Premium colors unlocked in game
- [ ] Premium badge shows on profile
- [ ] Premium badge shows on leaderboard
- [ ] Payment with declined card fails appropriately
- [ ] Cancel button returns to profile
- [ ] Webhook confirms payment (if configured)

## Support

- Stripe Documentation: https://stripe.com/docs
- Stripe Test Cards: https://stripe.com/docs/testing
- Stripe Dashboard: https://dashboard.stripe.com/
