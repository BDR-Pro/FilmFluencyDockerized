#!/bin/sh

# Read secrets and export them as environment variables
if [ -f /run/secrets/django_secret ]; then
  export SECRET_KEY=$(cat /run/secrets/django_secret)
fi

if [ -f /run/secrets/db_password ]; then
  export DB_PASS=$(cat /run/secrets/db_password)
fi

if [ -f /run/secrets/email_host_password ]; then
  export EMAIL_HOST_PASSWORD=$(cat /run/secrets/email_host_password)
fi

if [ -f /run/secrets/redis_password ]; then
  export RD_PASS=$(cat /run/secrets/redis_password)
fi

if [ -f /run/secrets/api_secret ]; then
  export API_SECRET_KEY=$(cat /run/secrets/api_secret)
fi

# Check which command to run
if [ "$1" = "web" ]; then
  shift  # Remove the first argument ("web")
  exec gunicorn --workers 3 --bind 0.0.0.0:8000 FilmFluency.wsgi:application "$@"
elif [ "$1" = "api" ]; then
  shift  # Remove the first argument ("api")
  exec gunicorn --workers 3 --bind 0.0.0.0:8080 api_app.wsgi:application "$@"
else
  exec "$@"
fi
