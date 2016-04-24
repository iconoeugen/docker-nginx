#!/bin/bash -x

set -o errexit

# command line parameter has precedence to environment variable
# and ensure is uppercase
SERVICE_NAME=${1:-${SERVICE_NAME^^}}
SERVICE_NAME=${SERVICE_NAME//-/_}
: ${SERVICE_NAME:?"Not defined"}

# SERVICE_HOST is manadatory
SERVICE_HOST=${SERVICE_NAME}_SERVICE_HOST
SERVICE_HOST=${!SERVICE_HOST}
: ${SERVICE_HOST?"Not defined"}
# SERVICE_PORT is optional
SERVICE_PORT=${SERVICE_NAME}_SERVICE_PORT
SERVICE_PORT=${!SERVICE_PORT}

# Generate proxy config for nginx server
cat ${NGINX_DOL_PATH}/config/nginx.vh.proxy.conf.in | \
sed "1 i\\
upstream theservice { \\
  server ${SERVICE_HOST}${SERVICE_PORT:+:}${SERVICE_PORT}; \\
} \\
" > /etc/nginx/conf.d/default.conf

nginx -g "daemon off;"
