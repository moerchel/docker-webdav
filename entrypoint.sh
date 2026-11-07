#!/bin/sh
# Prepares nginx from the environment variables (see README "Options") and
# starts the command given to the container, by default nginx.
set -eu

error() {
  echo "ERROR: $*" >&2
  exit 1
}

conf=/etc/nginx/webdav
data=/media/data
logs=/media/logs

# --- User and group of the nginx workers (owner of new files)
uid=${PUID:-}
gid=${PGID:-}
case $uid in *[!0-9]*) error "PUID must be a number, got '$uid'" ;; esac
case $gid in *[!0-9]*) error "PGID must be a number, got '$gid'" ;; esac
if [ "$uid" = 0 ] || [ "$gid" = 0 ]; then
  error "PUID and PGID must not be 0 (root)"
fi
if [ -n "$gid" ] && [ "$gid" != "$(id -g www-data)" ]; then
  groupmod -o -g "$gid" www-data
fi
if [ -n "$uid" ] && [ "$uid" != "$(id -u www-data)" ]; then
  usermod -o -u "$uid" www-data
fi
chown -R www-data:www-data /var/lib/nginx
echo "Files are written as user www-data ($(id -u www-data):$(id -g www-data))"

mkdir -p "$data" "$logs"
if ! setpriv --reuid=www-data --regid=www-data --init-groups test -w "$data"; then
  echo "Making $data writable for www-data"
  chown www-data:www-data "$data"
fi

# --- Authentication
user=${USERNAME:-}
pass=${PASSWORD:-}
file=${HTPASSWD_FILE:-}
rm -f "$conf/htpasswd"
if [ -n "$file" ]; then
  if [ -n "$user" ] || [ -n "$pass" ]; then
    error "Set either USERNAME/PASSWORD or HTPASSWD_FILE, not both"
  fi
  [ -r "$file" ] || error "HTPASSWD_FILE '$file' doesn't exist or isn't readable"
  cp "$file" "$conf/htpasswd"
  echo "Authentication: users from $file"
elif [ -n "$user" ] || [ -n "$pass" ]; then
  if [ -z "$user" ] || [ -z "$pass" ]; then
    error "Set both USERNAME and PASSWORD"
  fi
  printf '%s\n' "$pass" | htpasswd -iBc "$conf/htpasswd" "$user" 2>/dev/null \
    || error "Invalid USERNAME '$user'"
  echo "Authentication: user $user"
else
  echo "WARNING: No USERNAME/PASSWORD or HTPASSWD_FILE set, everybody who can" \
       "reach the server can read, change and delete all files" >&2
fi
if [ -f "$conf/htpasswd" ]; then
  chgrp www-data "$conf/htpasswd"
  chmod 640 "$conf/htpasswd"
  printf 'auth_basic "WebDAV";\nauth_basic_user_file %s/htpasswd;\n' "$conf" > "$conf/auth.conf"
else
  : > "$conf/auth.conf"
fi

# --- Proxies whose X-Forwarded-For header is trusted for the client address
set -f
proxies=$(printf '%s' "${TRUSTED_PROXIES:-}" | tr ',' ' ')
: > "$conf/realip.conf"
for p in $proxies; do
  case $p in
    *[!0-9A-Fa-f.:/]*) error "TRUSTED_PROXIES: invalid address '$p'" ;;
  esac
  echo "set_real_ip_from $p;" >> "$conf/realip.conf"
done
set +f
if [ -s "$conf/realip.conf" ]; then
  printf 'real_ip_header X-Forwarded-For;\nreal_ip_recursive on;\n' >> "$conf/realip.conf"
  echo "Client address from X-Forwarded-For of: $proxies"
fi

if [ "${1:-}" = nginx ]; then
  nginx -t -q || error "Invalid nginx configuration"
  # Log files in $logs: rotated once a day, checked every hour
  (
    while sleep 3600; do
      logrotate -s "$logs/.logrotate.status" /etc/logrotate.d/webdav
    done
  ) &
fi

exec "$@"
