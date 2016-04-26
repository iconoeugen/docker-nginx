FROM centos:7
MAINTAINER The DevOpsLab Project <DevOpsLab@telekom.de>
LABEL name="DevOpsLab Nginx Reverse Proxy Base Image"

ENV DOL_BASE_DIR /opt/dol
ENV DOL_TMPL_DIR ${DOL_BASE_DIR}/nginx

# First of all we need the Nginx package.
RUN yum -y install epel-release \
    && yum -y install nginx \
    && yum clean all

# Prepare Nginx proxy configuration.
RUN mkdir -p ${DOL_TMPL_DIR}
COPY config/nginx.vh.proxy.conf.in ${DOL_TMPL_DIR}/
COPY config/nginx.conf /etc/nginx/nginx.conf

# Relax permissions for nginx directories
RUN chmod g+rwx /var/lib/nginx \
    && chmod g+rwx /etc/nginx/conf.d \
    && chmod g+rwx /var/log/nginx \
    && chgrp -c root /var/log/nginx

# And not the docker entrypoint script.
COPY entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
