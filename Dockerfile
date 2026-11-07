# Deliberately the current Debian stable release, see README "Available image tags"
FROM debian:stable-slim

LABEL org.opencontainers.image.title="docker-webdav" \
      org.opencontainers.image.description="WebDAV server on nginx" \
      org.opencontainers.image.source="https://github.com/moerchel/docker-webdav" \
      org.opencontainers.image.licenses="MIT"

# "apt-get upgrade" pulls in updates published since the base image was built.
# hadolint ignore=DL3005,DL3008
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
         nginx \
         libnginx-mod-http-dav-ext \
         libnginx-mod-http-headers-more-filter \
         apache2-utils \
         logrotate \
    && rm -rf /var/lib/apt/lists/* /etc/nginx/sites-enabled/* /etc/logrotate.d/nginx \
    && mkdir -p /etc/nginx/webdav /media/data /media/logs \
    && chown www-data:www-data /media/data

COPY nginx.conf /etc/nginx/nginx.conf
COPY webdav.conf /etc/nginx/conf.d/webdav.conf
COPY logrotate.conf /etc/logrotate.d/webdav
COPY --chmod=755 entrypoint.sh healthcheck.sh /usr/local/bin/

VOLUME ["/media/data", "/media/logs"]
EXPOSE 80

HEALTHCHECK --interval=60s --timeout=10s --start-period=10s --retries=3 \
  CMD ["/usr/local/bin/healthcheck.sh"]

# SIGQUIT lets nginx finish running requests (e.g. uploads) before it stops
STOPSIGNAL SIGQUIT
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
