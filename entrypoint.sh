#!/bin/bash

set -o errexit

: ${DEBUG:=0}
[[ ${DEBUG} -eq 1 ]] && set -x

# Nginx server configuration
: ${PROXY_SENDFILE:=on}
: ${PROXY_TCP_NOPUSH:=off}
: ${PROXY_KEEP_ALIVE_TIMEOUT:=65}

# Enable HTTP proxy server
: ${PROXY_HTTP_ENABLED:=1}

# Enable HTTPS proxy server
: ${PROXY_HTTPS_ENABLED:=0}
: ${PROXY_SSL_DH_SIZE:=256}
: ${PROXY_SSL_DH_PATH:=/etc/nginx/certs/dh.pem}
: ${PROXY_SSL_KEY_PATH:=/etc/nginx/certs/cert.key}
: ${PROXY_SSL_CERT_PATH:=/etc/nginx/certs/cert.pem}

# Service name is mandatory
: ${SERVICE_NAME:?"Not defined"}
SERVICE_NAME=${SERVICE_NAME^^}
SERVICE_NAME=${SERVICE_NAME//-/_}

# Default protocol is http
: ${SERVICE_PROTO:=http}

# SERVICE_HOST is manadatory
SERVICE_HOST=${SERVICE_NAME}_SERVICE_HOST
SERVICE_HOST=${!SERVICE_HOST}
: ${SERVICE_HOST?"Not defined"}

# SERVICE_PORT is optional
SERVICE_PORT=${SERVICE_NAME}_SERVICE_PORT
SERVICE_PORT=${!SERVICE_PORT}

# Service remote address
SERVICE_ADDR="${SERVICE_HOST}${SERVICE_PORT:+:${SERVICE_PORT}}"

echo "Proxy service URL: ${SERVICE_PROTO}://${SERVICE_ADDR}"

[[ ${PROXY_HTTP_ENABLED} -ne 1 && ${PROXY_HTTPS_ENABLED} -ne 1 ]] \
    && >&2 echo "At least one of 'PROXY_HTTP_ENABLED' or 'PROXY_HTTPS_ENABLED' must be '1'!" \
    && exit 1

# Replace all set environment variables from in the current shell session.
# The environment variables present in the file but are unset will remain untouched.
# Replaced pattern is: ${<ENV_VAR>}
function substenv {
  local in_file="$1"
  local out_file="$2"
  cp "${in_file}" "${out_file}"
  compgen -v | while read var ; do
    sed -i "s/\${$var}/$(echo ${!var} | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')/g" "${out_file}"
  done
}

# Generate proxy config for nginx server
echo "Configure Nginx server."
substenv ${DOL_TMPL_DIR}/nginx.vh.proxy.conf.in /etc/nginx/conf.d/proxy.conf

# Configure HTTP server
if [[ ${PROXY_HTTP_ENABLED} -eq 1 ]] ; then
    echo "Enable Nginx HTTP proxy server."
    substenv ${DOL_TMPL_DIR}/nginx.vh.proxy-http.conf.in /etc/nginx/conf.d/proxy-http.conf
fi

# Configure HTTPS server
if [[ ${PROXY_HTTPS_ENABLED} -eq 1 ]] ; then
    echo "Enable Nginx HTTPS proxy server."
    substenv ${DOL_TMPL_DIR}/nginx.vh.proxy-https.conf.in /etc/nginx/conf.d/proxy-https.conf

    if [ ! -e "${PROXY_SSL_DH_PATH}" ]
    then
        echo "Generating DH(${PROXY_SSL_DH_SIZE}): ${PROXY_SSL_DH_PATH}."
        openssl dhparam -out "${PROXY_SSL_DH_PATH}" "${PROXY_SSL_DH_SIZE}"
    fi

    if [ ! -e "${PROXY_SSL_KEY_PATH}" ] || [ ! -e "${PROXY_SSL_CERT_PATH}" ]
    then
        echo "Generating self signed certificate."
        openssl req -x509 -newkey rsa:4086 \
            -subj "/C=XX/ST=XXXX/L=XXXX/O=XXXX/CN=localhost" \
            -keyout "${PROXY_SSL_KEY_PATH}" \
            -out "${PROXY_SSL_CERT_PATH}" \
            -days 3650 -nodes -sha256
    fi
fi

if [[ $# -ge 1 ]]; then
    echo "$@"
    exec $@
else
    echo "Starting Nginx proxy server."
    exec nginx -g "daemon off;"
fi
