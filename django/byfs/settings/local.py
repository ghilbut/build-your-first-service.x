from byfs.settings.base import *


DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': os.environ.get('BYFS_DB_DEFAULT_NAME', 'byfs'),
        'HOST': os.environ.get('BYFS_DB_DEFAULT_HOST', '127.0.0.1'),
        'PORT': os.environ.get('BYFS_DB_DEFAULT_PORT', '3306'),
        'USER': os.environ.get('BYFS_DB_DEFAULT_USER', 'byfs'),
        'PASSWORD': os.environ.get('BYFS_DB_DEFAULT_PASSWORD', 'byfspw'),
        'CONN_MAX_AGE': 60,
    }
}
