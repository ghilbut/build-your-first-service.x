ARG PYTHON_VERSION=3.8

################################################################
##
##  Build dependencies in separate container
##

FROM python:3.8-alpine AS builder

WORKDIR /app

COPY Pipfile* ./

RUN apk add --no-cache build-base \
 && pip install --no-cache-dir pipenv \
 && pipenv install --system --deploy --clear

################################################################
##
##  Create the final container with the app
##

FROM python:3.8-alpine

EXPOSE 8000
WORKDIR /app

ENV USER=docker \
    GROUP=docker \
    UID=20000 \
    GID=20000 \
    HOME=/app \
    PYTHONUNBUFFERED=1

RUN addgroup --gid "${GID}" "${GROUP}" \
 && adduser --disabled-password \
            --gecos "" \
            --home "$(pwd)" \
            --ingroup "${GROUP}" \
            --no-create-home \
            --uid "${UID}" \
            "${USER}"

USER ${USER}
COPY --from=builder /usr/local/lib/python3.8/site-packages /usr/local/lib/python3.8/site-packages
COPY --from=builder /usr/local/bin/uvicorn /usr/local/bin/uvicorn
COPY --chown=${USER}:${GROUP} . .

ENTRYPOINT ["uvicorn", "--host", "0", "byfs.asgi:application"]
