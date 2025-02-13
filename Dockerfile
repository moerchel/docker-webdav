FROM nginx:stable-bookworm

LABEL maintainer="moerchel"

RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y logrotate nginx-extras apache2-utils

COPY nginx_logrotate /etc/logrotate.d/

COPY nginx_webdav.conf /etc/nginx/conf.d/default.conf
RUN rm /etc/nginx/sites-enabled/*

RUN mkdir -p "/media/data"
RUN chown -R www-data:www-data "/media/data"
VOLUME /media/data

RUN mkdir -p "/media/logs"
RUN chown -R www-data:www-data "/media/logs"
VOLUME /media/logs

COPY entrypoint.sh /
RUN chmod +x entrypoint.sh
CMD /entrypoint.sh && nginx -g "daemon off;"
