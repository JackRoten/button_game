from django.shortcuts import render, redirect
from django.contrib.auth import login, authenticate
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.http import JsonResponse, HttpResponse
from django.views.decorators.http import require_POST
from django.views.decorators.csrf import csrf_exempt
from django.conf import settings
from django.db.models import F, Sum
from django.db import models
import stripe
import json
from .forms import SignUpForm
from .models import UserProfile, Click

# Configure Stripe
stripe.api_key = settings.STRIPE_SECRET_KEY


def home(request):
    """Home page view"""
    return render(request, 'home.html')


def signup(request):
    """User registration view"""
    if request.method == 'POST':
        form = SignUpForm(request.POST)
        if form.is_valid():
            user = form.save()
            # Create user profile
            UserProfile.objects.create(user=user)
            # Create click tracker
            Click.objects.create(user=user)
            
            # Log the user in
            username = form.cleaned_data.get('username')
            password = form.cleaned_data.get('password1')
            user = authenticate(username=username, password=password)
            login(request, user)
            
            messages.success(request, f'Welcome {username}! Your account has been created.')
            return redirect('game')
    else:
        form = SignUpForm()
    
    return render(request, 'registration/signup.html', {'form': form})


@login_required
def profile(request):
    """User profile view"""
    try:
        user_profile = request.user.userprofile
    except UserProfile.DoesNotExist:
        # Create profile if it doesn't exist
        user_profile = UserProfile.objects.create(user=request.user)
    
    try:
        click_record = request.user.clicks.first()
    except:
        click_record = Click.objects.create(user=request.user)
    
    context = {
        'user_profile': user_profile,
        'click_record': click_record,
    }
    return render(request, 'profile.html', context)


@login_required
def game(request):
    """Main game page with the color-changing button"""
    try:
        user_profile = request.user.userprofile
    except UserProfile.DoesNotExist:
        user_profile = UserProfile.objects.create(user=request.user)
    
    try:
        click_record = request.user.clicks.first()
        if not click_record:
            click_record = Click.objects.create(user=request.user)
    except:
        click_record = Click.objects.create(user=request.user)
    
    context = {
        'user_profile': user_profile,
        'click_record': click_record,
    }
    return render(request, 'game.html', context)


def leaderboard(request):
    """Leaderboard view showing top players"""
    # Get all click records ordered by click count
    top_players = Click.objects.select_related('user', 'user__userprofile').order_by('-click_count')[:100]
    
    # Get current user's rank if logged in
    user_rank = None
    user_click_record = None
    if request.user.is_authenticated:
        try:
            user_click_record = request.user.clicks.first()
            if user_click_record:
                # Count how many players have more clicks than the current user
                user_rank = Click.objects.filter(click_count__gt=user_click_record.click_count).count() + 1
        except:
            pass
    
    # Get total stats
    total_players = Click.objects.filter(click_count__gt=0).count()
    total_clicks = Click.objects.aggregate(total=models.Sum('click_count'))['total'] or 0
    
    context = {
        'top_players': top_players,
        'user_rank': user_rank,
        'user_click_record': user_click_record,
        'total_players': total_players,
        'total_clicks': total_clicks,
    }
    return render(request, 'leaderboard.html', context)


@login_required
@require_POST
def button_click(request):
    """Handle button click via AJAX"""
    try:
        # Get or create click record for user
        click_record, created = Click.objects.get_or_create(
            user=request.user,
            defaults={'click_count': 0}
        )
        
        # Increment click count
        click_record.click_count += 1
        click_record.save()
        
        # Return JSON response with updated count
        return JsonResponse({
            'success': True,
            'click_count': click_record.click_count,
            'message': f'Click #{click_record.click_count}!'
        })
    
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=400)


@login_required
def create_checkout_session(request):
    """Create a Stripe checkout session for premium upgrade"""
    try:
        # Get or create user profile
        user_profile, created = UserProfile.objects.get_or_create(user=request.user)
        
        # Check if user is already premium
        if user_profile.is_premium:
            messages.info(request, 'You already have premium access!')
            return redirect('profile')
        
        # Create Stripe checkout session
        checkout_session = stripe.checkout.Session.create(
            customer_email=request.user.email,
            payment_method_types=['card'],
            line_items=[
                {
                    'price_data': {
                        'currency': 'usd',
                        'unit_amount': settings.STRIPE_PREMIUM_PRICE,
                        'product_data': {
                            'name': 'Button Game Premium',
                            'description': 'Unlock exclusive button colors and premium features!',
                        },
                    },
                    'quantity': 1,
                },
            ],
            mode='payment',
            success_url=request.build_absolute_uri('/payment/success/') + '?session_id={CHECKOUT_SESSION_ID}',
            cancel_url=request.build_absolute_uri('/payment/cancel/'),
            metadata={
                'user_id': request.user.id,
            }
        )
        
        return redirect(checkout_session.url)
    
    except Exception as e:
        messages.error(request, f'Error creating checkout session: {str(e)}')
        return redirect('profile')


@login_required
def payment_success(request):
    """Handle successful payment"""
    session_id = request.GET.get('session_id')
    
    if session_id:
        try:
            # Retrieve the session from Stripe
            session = stripe.checkout.Session.retrieve(session_id)
            
            # Verify payment was successful
            if session.payment_status == 'paid':
                # Update user to premium
                user_profile, created = UserProfile.objects.get_or_create(user=request.user)
                user_profile.is_premium = True
                user_profile.stripe_customer_id = session.customer
                user_profile.save()
                
                messages.success(request, '🎉 Welcome to Premium! You now have access to all button colors!')
                return render(request, 'payment/success.html')
        except Exception as e:
            messages.error(request, f'Error verifying payment: {str(e)}')
    
    return redirect('profile')


@login_required
def payment_cancel(request):
    """Handle cancelled payment"""
    messages.info(request, 'Payment cancelled. You can upgrade to premium anytime!')
    return render(request, 'payment/cancel.html')


@csrf_exempt
@require_POST
def stripe_webhook(request):
    """Handle Stripe webhook events"""
    payload = request.body
    sig_header = request.META.get('HTTP_STRIPE_SIGNATURE')
    
    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, settings.STRIPE_WEBHOOK_SECRET
        )
    except ValueError:
        # Invalid payload
        return HttpResponse(status=400)
    except stripe.error.SignatureVerificationError:
        # Invalid signature
        return HttpResponse(status=400)
    
    # Handle the checkout.session.completed event
    if event['type'] == 'checkout.session.completed':
        session = event['data']['object']
        
        # Get user ID from metadata
        user_id = session.get('metadata', {}).get('user_id')
        
        if user_id:
            try:
                from django.contrib.auth.models import User
                user = User.objects.get(id=user_id)
                user_profile, created = UserProfile.objects.get_or_create(user=user)
                user_profile.is_premium = True
                user_profile.stripe_customer_id = session.get('customer')
                user_profile.save()
            except User.DoesNotExist:
                pass
    
    return HttpResponse(status=200)
