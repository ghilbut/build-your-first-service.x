from byfs.settings.base import *


ALLOWED_HOSTS = [
  'byfs-dev.api.ghilbut.com',
]


#DATABASES = {
#    'default': {
#        'ENGINE': 'django.db.backends.mysql',
#        'NAME': os.environ['BYFS_DB_DEVELOP_NAME'],
#        'HOST': os.environ['BYFS_DB_DEVELOP_HOST'],
#        'PORT': os.environ['BYFS_DB_DEVELOP_PORT'],
#        'USER': os.environ['BYFS_DB_DEVELOP_USER'],
#        'PASSWORD': os.environ['BYFS_DB_DEVELOP_PASSWORD'],
#        'CONN_MAX_AGE': 60,
#    }
#}
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),
    }
}
