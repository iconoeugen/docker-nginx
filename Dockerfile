FROM centos:7
MAINTAINER The DevOpsLab Project <DevOpsLab@telekom.de>
LABEL name="DevOpsLab Nginx Reverse Proxy Base Image"

ENV NGINX_DOL_PATH /opt/dol/nginx

RUN yum -y install epel-release \
    && yum -y install nginx \
    && yum clean all

RUN mkdir -p ${NGINX_DOL_PATH}/config

COPY entrypoint.sh /entrypoint.sh
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/nginx.vh.proxy.conf.in ${NGINX_DOL_PATH}/config

RUN chmod a+x /entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
