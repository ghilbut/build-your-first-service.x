
## Local Development Environments

### Local Database

**.env**
```bash
$ tee .env << EOF
DJANGO_SETTINGS_MODULE=byfs.settings.local
EOF

$ docker-compose up -d
$ pipenv run ./manage.py makemigrations
$ pipenv run ./manage.py migrate
$ pipenv run ./manage.py createsuperuser
Email address: ****@****.***
Password:
Password (again):

$ pipenv run ./manage.py runserver 0:8000
```

* http://localhost:8000
* http://localhost:8000/admin

### Develop Database

```bash
$ tee .env << EOF
DJANGO_SETTINGS_MODULE=byfs.settings.develop

BYFS_DB_DEVELOP_NAME=********
BYFS_DB_DEVELOP_HOST=********
BYFS_DB_DEVELOP_PORT=********
BYFS_DB_DEVELOP_USER=********
BYFS_DB_DEVELOP_PASSWORD=********
EOF

$ docker-compose up -d
$ pipenv run ./manage.py makemigrations
$ pipenv run ./manage.py migrate
$ pipenv run ./manage.py createsuperuser
Email address: ****@****.***
Password:
Password (again):

$ pipenv run ./manage.py runserver 0:8000
```

* http://localhost:8000
* http://localhost:8000/admin

