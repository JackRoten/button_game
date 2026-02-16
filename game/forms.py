from django import forms
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth.models import User


class SignUpForm(UserCreationForm):
    """Custom sign up form with email field"""
    email = forms.EmailField(
        max_length=254, 
        required=True,
        help_text='Required. Enter a valid email address.'
    )
    
    class Meta:
        model = User
        fields = ('username', 'email', 'password1', 'password2')
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Add CSS classes to form fields for styling
        for field_name in self.fields:
            self.fields[field_name].widget.attrs['class'] = 'form-control'
