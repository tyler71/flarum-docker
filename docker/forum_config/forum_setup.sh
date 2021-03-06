#!/usr/bin/env bash
set -e
cd "$APPLICATION_PATH"

mkdir -p \
  /app/public/assets/avatars    \
  /app/public/assets/extensions \
  /app/public/assets/files      \
  /app/public/assets/images     \
  /app/storage

if [ -f /conf/config.php ]; then
  ln -fs /conf/config.php ./config.php
  php flarum migrate
  php flarum cache:clear

elif [ "$INSTALL" == "true" ]; then
  cat > install.yml <<EOF
debug: true
baseUrl: ${HOSTNAME}
databaseConfiguration:
  driver: mysql
  host: db
  port: 3306
  database: ${MYSQL_DATABASE}
  username: ${MYSQL_USER}
  password: ${MYSQL_PASSWORD}
  prefix:
adminUser:
  username: admin
  password: password
  email: admin@example.com
settings:
EOF
  php flarum install --file install.yml
  mv config.php /conf/config.php
  chown "${PUID_ID}" /conf/config.php
  ln -fs /conf/config.php ./config.php
fi

chown "${PUID_ID}" -R  \
  /app/public/assets \
  /app/storage
