"""byfs URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/3.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path

urlpatterns = [
    path('admin/', admin.site.urls),
]



from django.http import HttpResponse

def index(request):
    import os
    err = 'error'
    v = {
      'DJANGO_SETTINGS_MODULE': os.environ.get('DJANGO_SETTINGS_MODULE', err),
      'BYFS_DB_DEVELOP_HOST': os.environ.get('BYFS_DB_DEVELOP_HOST', err),
      'BYFS_DB_DEVELOP_PORT': os.environ.get('BYFS_DB_DEVELOP_PORT', err),
      'BYFS_DB_DEVELOP_NAME': os.environ.get('BYFS_DB_DEVELOP_NAME', err),
      'BYFS_DB_DEVELOP_USER': os.environ.get('BYFS_DB_DEVELOP_USER', err),
      'BYFS_DB_DEVELOP_PASSWORD': os.environ.get('BYFS_DB_DEVELOP_PASSWORD', err),
    }
    import json
    v = json.dumps(v, indent=2, sort_keys=True)
    return HttpResponse("Hello, world. You're at the polls index.<br/><br/>" + v)

urlpatterns.append(path('hello/', index, name='hello'))
