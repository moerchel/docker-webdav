FROM nginx:latest

LABEL maintainer="moerchel"

RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y nginx-extras apache2-utils

COPY nginx_webdav.conf /etc/nginx/conf.d/default.conf
RUN rm /etc/nginx/sites-enabled/*

RUN mkdir -p "/webdav_data"

RUN chown -R www-data:www-data "/webdav_data"

VOLUME /webdav_data

COPY entrypoint.sh /
RUN chmod +x entrypoint.sh
CMD /entrypoint.sh && nginx -g "daemon off;"
