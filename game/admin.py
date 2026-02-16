from django.contrib import admin
from .models import UserProfile, Click


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'is_premium', 'stripe_customer_id')
    list_filter = ('is_premium',)
    search_fields = ('user__username', 'user__email')


@admin.register(Click)
class ClickAdmin(admin.ModelAdmin):
    list_display = ('user', 'click_count', 'last_clicked')
    list_filter = ('last_clicked',)
    search_fields = ('user__username',)
    ordering = ('-click_count',)
