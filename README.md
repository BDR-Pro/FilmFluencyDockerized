# 📽️ FilmFluency Dockerized Project

Welcome to the FilmFluency Dockerized Project! This project sets up a comprehensive development environment using Docker, featuring a Django web application, API, Nginx, Rocket.Chat, and TeamSpeak.

## 🎬 Introduction

The FilmFluency Dockerized Project provides a robust setup for developing and running the FilmFluency and FilmFluency Game projects along with supporting services. This setup uses Docker to ensure a consistent development and production environment.

## 🚀 Prerequisites

Make sure you have the following installed:

- Docker
- Docker Compose
- Git

## 🔧 Setup

### 1. Cloning Repositories

First, clone the necessary repositories:

```sh
git clone https://github.com/yourusername/filmfluency.git
git clone https://github.com/yourusername/filmfluency-game.git
git clone https://github.com/yourusername/api-mobile-app.git
```

### 2. Creating Secrets

Create a `secrets` directory and add the necessary secret files:

```sh
mkdir secrets
echo "your_django_secret_key" > secrets/django_secret.txt
echo "your_db_password" > secrets/db_password.txt
echo "your_email_host_password" > secrets/email_host_password.txt
echo "your_redis_password" > secrets/redis_password.txt
echo "your_api_secret_key" > secrets/api_secret.txt
```

### 3. Environment Variables

Create a `.env` file in the root of your project and add the following environment variables:

```env
SECRET_KEY=your_secret_key
ACCESS_KEY=your_access_key
TAP_SECRET_KEY=your_tap_secret_key
DB_PASS=your_db_password
EMAIL_HOST_USER=your_email_host_user
EMAIL_HOST_PASSWORD=your_email_host_password
TMDB_API_KEY=your_tmdb_api_key
RD_PASS=your_redis_password
API_SECRET_KEY=your_api_secret_key
```

### 4. Docker Compose

Here’s the `docker-compose.yml` file for setting up all services:

```yaml
version: '3.8'

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile.web
    ports:
      - "8000:8000"
    env_file:
      - .env
    secrets:
      - django_secret
      - db_password
      - email_host_password
      - redis_password
    depends_on:
      - db
      - nginx

  nginx:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - web

  rocket_chat:
    image: rocketchat/rocket.chat:latest
    environment:
      - MONGO_URL=mongodb://mongo:27017/rocketchat
      - ROOT_URL=http://localhost:3000
      - PORT=3000
    ports:
      - "3000:3000"
    depends_on:
      - mongo

  mongo:
    image: mongo:latest
    volumes:
      - mongo_data:/data/db

  teamspeak:
    image: teamspeak
    environment:
      - TS3SERVER_LICENSE=accept
    ports:
      - "9987:9987/udp"
      - "10011:10011"
      - "30033:30033"

  api:
    build:
      context: .
      dockerfile: Dockerfile.api
    ports:
      - "8080:8080"
    env_file:
      - .env
    secrets:
      - api_secret

volumes:
  mongo_data:

secrets:
  django_secret:
    file: ./secrets/django_secret.txt
  db_password:
    file: ./secrets/db_password.txt
  email_host_password:
    file: ./secrets/email_host_password.txt
  redis_password:
    file: ./secrets/redis_password.txt
  api_secret:
    file: ./secrets/api_secret.txt
```

### Combined `entrypoint.sh`

Here is the `entrypoint.sh` script to handle environment variables for both web and API services:

```sh
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
```

### Dockerfile for Web Service (`Dockerfile.web`)

```dockerfile
# Use an official Python runtime as a parent image
FROM python:3.13.0b1-slim

# Set the working directory in the container
WORKDIR /usr/src/app

# Install Git, necessary libraries, and system utilities
RUN apt-get update && apt-get install -y \
    libpq-dev \
    gcc \
    python3-dev \
    musl-dev \
    git \
    build-essential \
    clang \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip install --upgrade pip setuptools

# Install Gunicorn
RUN pip install gunicorn 

# Clone the specific Git repositories
RUN git clone https://github.com/yourusername/filmfluency.git
RUN git clone https://github.com/yourusername/filmfluency-game.git

# Install any needed packages specified in requirements.txt
COPY filmfluency/requirements.txt .
RUN pip install -r requirements.txt

# Expose port 8000 to the outside once the container has launched
EXPOSE 8000

# Copy the entrypoint script into the container
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# cd into the Django project directory
WORKDIR /usr/src/app/filmfluency

# Define the entrypoint and command to run your Django application using Gunicorn
ENTRYPOINT ["/entrypoint.sh"]
CMD ["web"]
```

### Dockerfile for API Service (`Dockerfile.api`)

```dockerfile
# Use an official Python runtime as a parent image
FROM python:3.13.0b1-slim

# Set the working directory in the container
WORKDIR /usr/src/app

# Install Git, necessary libraries, and system utilities
RUN apt-get update && apt-get install -y \
    libpq-dev \
    gcc \
    python3-dev \
    musl-dev \
    git \
    build-essential \
    clang \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip install --upgrade pip setuptools

# Install Gunicorn
RUN pip install gunicorn

# Clone the specific Git repository for the API
RUN git clone https://github.com/yourusername/api-mobile-app.git

# Install any needed packages specified in requirements.txt
COPY api-mobile-app/requirements.txt .
RUN pip install -r requirements.txt

# Expose port 8080 to the outside once the container has launched
EXPOSE 8080

# Copy the entrypoint script into the container
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# cd into the API project directory
WORKDIR /usr/src/app/api-mobile-app

# Define the entrypoint and command to run your API application using Gunicorn
ENTRYPOINT ["/entrypoint.sh"]
CMD ["api"]
```

## ▶️ Running the Project

To start the entire setup, run:

```sh
docker-compose up --build
```

This command builds and starts all services defined in the `docker-compose.yml` file.

## 📚 Services Overview

- **Web**: Runs the Django application for FilmFluency.
- **Nginx**: Serves as a reverse proxy for the web and API services.
- **Rocket.Chat**: Provides chat functionality.
- **MongoDB**: Database for Rocket.Chat.
- **TeamSpeak**: Voice communication service.
- **API**: Runs the API for the mobile app.

## 🌐 Subdomains Configuration

Set up subdomains for different services

:

- `hub.filmfluency`: Points to the Django web application.
- `voice.filmfluency`: Points to TeamSpeak.
- `game.filmfluency`: Points to the API service.

## 🛠️ Troubleshooting

- **Service Not Starting**: Check the logs for the specific service using `docker-compose logs <service_name>`.
- **Environment Variables**: Ensure all environment variables are set correctly in the `.env` file and secrets are properly created.
- **Port Conflicts**: Make sure the ports defined in the `docker-compose.yml` file are not being used by other applications.

## 🤝 Contributing

We welcome contributions! Feel free to fork the repositories, make changes, and submit pull requests.

## 📜 License

This project is licensed under the MIT License.

---

Enjoy developing with the FilmFluency Dockerized Project! 🚀
