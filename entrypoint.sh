#!/bin/bash

set -o errexit

: ${DEBUG:=0}
[[ ${DEBUG} -eq 1 ]] && set -x

# Nginx core configuration
: ${NGINX_WORKER_PROCESSES:=1}
: ${NGINX_WORKER_CONNECTIONS:=512}

# Nginx server configuration
: ${NGINX_SEND_TIMEOUT:=60s}
: ${NGINX_SENDFILE:=off}
: ${NGINX_TCP_NODELAY:=off}
: ${NGINX_TCP_NOPUSH:=off}
: ${NGINX_KEEP_ALIVE_TIMEOUT:=75s}
: ${NGINX_CLIENT_HEADER_TIMEOUT:=8s}
: ${NGINX_CLIEHT_HEADER_BUFFER_SIZE:=1k}
: ${NGINX_LARGE_CLIENT_HEADER_BUFFERS_NUMBER:=4}
: ${NGINX_LARGE_CLIENT_HEADER_BUFFERS_SIZE:=8k}
: ${NGINX_CLIENT_BODY_TIMEOUT:=8s}
: ${NGINX_CLIENT_BODY_BUFFER_SIZE:=1k}
: ${NGINX_CLIENT_MAX_BODY_SIZE:=1M}

# Enable HTTP proxy server
: ${NGINX_HTTP_ENABLED:=1}

# Enable HTTPS proxy server
: ${NGINX_HTTPS_ENABLED:=0}
: ${NGINX_SSL_DH_SIZE:=256}
: ${NGINX_SSL_DH_PATH:=/etc/nginx/certs/dh.pem}
: ${NGINX_SSL_KEY_PATH:=/etc/nginx/certs/cert.key}
: ${NGINX_SSL_CERT_PATH:=/etc/nginx/certs/cert.pem}

# Service name is mandatory
: ${SERVICE_NAME:?Not defined}
SERVICE_NAME=${SERVICE_NAME^^}
SERVICE_NAME=${SERVICE_NAME//-/_}

# Default protocol is http
: ${SERVICE_PROTO:=http}

# SERVICE_HOST is manadatory
SERVICE_HOST=${SERVICE_NAME}_SERVICE_HOST
SERVICE_HOST=${!SERVICE_HOST}
: ${SERVICE_HOST:?Not defined ${SERVICE_NAME}_SERVICE_HOST}

# SERVICE_PORT is optional
SERVICE_PORT=${SERVICE_NAME}_SERVICE_PORT
SERVICE_PORT=${!SERVICE_PORT}

# Service remote address
SERVICE_ADDR="${SERVICE_HOST}${SERVICE_PORT:+:${SERVICE_PORT}}"

echo "Proxy service URL: ${SERVICE_PROTO}://${SERVICE_ADDR}"

[[ ${NGINX_HTTP_ENABLED} -ne 1 && ${NGINX_HTTPS_ENABLED} -ne 1 ]] \
    && >&2 echo "At least one of 'NGINX_HTTP_ENABLED' or 'NGINX_HTTPS_ENABLED' must be '1'!" \
    && exit 1

# Replace all set environment variables from in the current shell session.
# The environment variables present in the file but are unset will remain untouched.
# Replaced pattern is: ${<ENV_VAR>}
function substenv {
  local in_file="$1"
  local out_file="$2"
  local temp_file=$(mktemp -t substenv.XXXX)
  cat "${in_file}" > ${temp_file}
  compgen -v | while read var ; do
    sed -i "s/\${$var}/$(echo ${!var} | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')/g" "${temp_file}"
  done
  cat "${temp_file}" > "${out_file}" && rm -f "${temp_file}"
}

# Generate core config for nginx server
echo "Configure Nginx core server."
substenv ${DOL_TMPL_DIR}/nginx.conf.in /etc/nginx/nginx.conf

# Generate proxy config for nginx server
echo "Configure Nginx proxy server."
substenv ${DOL_TMPL_DIR}/nginx.vh.proxy.conf.in /etc/nginx/conf.d/proxy.conf

# Configure HTTP server
if [[ ${NGINX_HTTP_ENABLED} -eq 1 ]] ; then
    echo "Enable Nginx HTTP proxy server."
    substenv ${DOL_TMPL_DIR}/nginx.vh.proxy-http.conf.in /etc/nginx/conf.d/proxy-http.conf
fi

# Configure HTTPS server
if [[ ${NGINX_HTTPS_ENABLED} -eq 1 ]] ; then
    echo "Enable Nginx HTTPS proxy server."
    substenv ${DOL_TMPL_DIR}/nginx.vh.proxy-https.conf.in /etc/nginx/conf.d/proxy-https.conf

    if [ ! -e "${NGINX_SSL_DH_PATH}" ]
    then
        echo "Generating DH(${NGINX_SSL_DH_SIZE}): ${NGINX_SSL_DH_PATH}."
        openssl dhparam -out "${NGINX_SSL_DH_PATH}" "${NGINX_SSL_DH_SIZE}"
    fi

    if [ ! -e "${NGINX_SSL_KEY_PATH}" ] || [ ! -e "${NGINX_SSL_CERT_PATH}" ]
    then
        echo "Generating self signed certificate."
        openssl req -x509 -newkey rsa:4086 \
            -subj "/C=XX/ST=XXXX/L=XXXX/O=XXXX/CN=localhost" \
            -keyout "${NGINX_SSL_KEY_PATH}" \
            -out "${NGINX_SSL_CERT_PATH}" \
            -days 3650 -nodes -sha256
    fi
fi

# Fix for logging on Docker 1.8 (See Docker issue #6880)
cat <> /var/log/nginx/access.log &
cat <> /var/log/nginx/error.log 1>&2 &

if [[ $# -ge 1 ]]; then
    echo "$@"
    exec $@
else
    echo "Starting Nginx proxy server."
    exec nginx -g "daemon off;"
fi
