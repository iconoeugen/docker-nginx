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
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/nginx.vh.proxy.conf.in config/nginx.vh.proxy-http.conf.in config/nginx.vh.proxy-https.conf.in ${DOL_TMPL_DIR}/

# Relax permissions for nginx directories
RUN for dir in /etc/nginx/conf.d /etc/nginx/certs /var/lib/nginx /var/run ; do \
    mkdir -p ${dir} && chmod -cR g+rwx ${dir} && chgrp -cR root ${dir} ; \
    done

# And not the docker entrypoint script.
COPY entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh

EXPOSE 8080 8443

ENTRYPOINT ["/entrypoint.sh"]
