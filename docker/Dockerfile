# ========== Install the forum and plugins
FROM webdevops/php-nginx:7.4 as builder
ARG EXTIVERSE_TOKEN

USER application
WORKDIR /app

RUN composer create-project flarum/flarum . --stability=beta
COPY .null composer.* ./

RUN if [ -n "$EXTIVERSE_TOKEN" ]; then composer config --global --auth bearer.extiverse.com "$EXTIVERSE_TOKEN"; fi
RUN composer install


# ========== Setup webserver
FROM webdevops/php-nginx:7.4 as production

ENV WEB_DOCUMENT_ROOT=/app/public
ENV PHP_DISMOD='amqp,apcu,bcmath,bz2,calendar,exif,gettext,imagick,imap,intl,ioncube,\
    ldap,memcached,mongodb,mysqli,pcntl,pdo_pgsql,pgsql,redis,shmop,soap,sockets,\
    sodium,sysvmsg,sysvsem,sysvshm,vips,xmlrpc,xsl'

VOLUME /app/public/assets

# COPY entrypoint script
COPY forum_config/forum_setup.sh /opt/docker/provision/entrypoint.d/50-forum_setup.sh

COPY --from=builder /app /app

WORKDIR /app


# ========== Setup dev
FROM production as dev
ARG EXTIVERSE_TOKEN

RUN if [ -n "$EXTIVERSE_TOKEN" ]; then composer config --global --auth bearer.extiverse.com "$EXTIVERSE_TOKEN"; fi
