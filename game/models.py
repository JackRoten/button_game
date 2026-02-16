from django.db import models
from django.contrib.auth.models import User


class UserProfile(models.Model):
    """Extended user profile with premium status"""
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    is_premium = models.BooleanField(default=False)
    stripe_customer_id = models.CharField(max_length=255, blank=True, null=True)
    
    def __str__(self):
        return f"{self.user.username}'s profile"


class Click(models.Model):
    """Track button clicks for each user"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='clicks')
    click_count = models.IntegerField(default=0)
    last_clicked = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-click_count']
    
    def __str__(self):
        return f"{self.user.username}: {self.click_count} clicks"
