from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from .forms import (
  UserCreationForm,
  UserChangeForm,
)
from .models import User


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
  add_form = UserCreationForm
  form = UserChangeForm
  model = User
  list_display = (
    'email',
    'is_active',
    'is_staff',
    'is_superuser',
 )
  list_filter = (
    'is_active',
    'is_staff',
    'is_superuser',
  )
  fieldsets = (
    ( None, { 'fields': ( 'email', 'password', ) } ),
    ( 'Permissions', { 'fields': ( 'is_active', 'is_staff', 'is_superuser', ) } ),
  )
  add_fieldsets = (
    ( 
      None, 
      {
        'classes': ( 'wide', ),
        'fields': ( 'email', 'password1', 'password2', 'is_active', 'is_staff', 'is_superuser', ),
      }
    ),
  ),
  readonly_fields = ( 'email', )
  search_fields = ( 'email', )
  ordering = ( 'email', )
