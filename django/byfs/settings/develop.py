from byfs.settings.base import *


DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': os.environ['BYFS_DB_DEVELOP_NAME'],
        'HOST': os.environ['BYFS_DB_DEVELOP_HOST'],
        'PORT': os.environ['BYFS_DB_DEVELOP_PORT'],
        'USER': os.environ['BYFS_DB_DEVELOP_USER'],
        'PASSWORD': os.environ['BYFS_DB_DEVELOP_PASSWORD'],
        'CONN_MAX_AGE': 60,
    }
}
