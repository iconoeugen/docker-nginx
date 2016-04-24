# Nginx Reverse-Proxy docker image

A docker image to run Nginx as Reverse-Proxy

> Keycloak website: [nginx.org](http://nginx.org/)

## Quick start

### Clone this project:

``` bash
git clone https://vm012.bn.detemobil.de/gitlab/docker-nginx
cd docker-nginx
```

### Make your own Nginx Reverse-Proxy docker image

Build your image:

``` bash
docker build -t dockernginx_nginx .
```

Run your image:

``` bash
docker run --name dockernginx_test -p 8080:8080 --detach dockernginx_nginx
```

To Check running container access the URL: (http://localhost:8080/)
```

Stop running container:

``` bash
docker stop dockernginx_test
```

Remove stopped container:

``` bash
docker rm dockernginx_test
```

## Docker compose

Compose is a tool for defining and running multi-container Docker applications, using a Compose file  to configure
the application services.

Build docker images:

``` bash
docker-compose build
```

Create and start docker containers with compose:

``` bash
docker-compose up -d
```

Stop docker containers

``` bash
docker-compose stop
```

Removed stopped containers:

``` bash
docker-compose rm
```

## Environment Variables

- **SERVICE_NAME**: Name of Service to be configured as reverse proxy. (Manadatory)
- **<SERVICE_NAME>_SERVICE_HOST**: Service hostname or IP to be configured as reverse proxy upstream. The name of the environment variable 
  is dependent on the provided *SERVICE_NAME* value; i.e. if *SERVICE_NAME=TEST* then the hostname environment variable has to be named *TEST_SERVICE_HOST* (Manadatory)
- **<SERVICE_NAME>_SERVICE_PORT**: Service port to be configured as reverse proxy upstream. The name of the environment variable is dependent on the provided *SERVICE_NAME* value. (Optional)

### Set your own environment variables

Environment variables can be set by adding the --env argument in the command line, for example:

``` bash
docker run \
  --env SERVICE_HOST="google.com" \
  --env SERVICE_PORT="80" \
  --name dockernginx_test \
  -p 8080:80 \
  --detach \
  dockernginx_nginx
```

