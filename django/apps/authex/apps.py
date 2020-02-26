from django.apps import AppConfig
from django.utils.translation import gettext_lazy as _


class AuthExConfig(AppConfig):
    name = 'apps.authex'
    verbose_name = _("Custom Authentication")
