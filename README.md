# docker-webdav

[WebDAV](https://en.wikipedia.org/wiki/WebDAV) server on [nginx](https://nginx.org), based on [Debian](https://www.debian.org) stable. Files can be read, uploaded, moved and deleted with WebDAV clients (Windows Explorer, macOS Finder, davfs2, rclone, …) and browsed with a web browser.

This image is available for the following architectures:

* amd64
* arm64
* armv7

## Security

* **Without `USERNAME`/`PASSWORD` or `HTPASSWD_FILE` there is no login:** everybody who can reach the port can read, change and delete all files. The container logs a warning in this case.
* The image speaks plain HTTP. Passwords and files are sent unencrypted. Outside a trusted network, put a reverse proxy with TLS in front of it (and bind the port to `127.0.0.1`, see [docker compose](#docker-compose)).

## Available image tags

Images are published on [GitHub Container Registry](https://github.com/moerchel/docker-webdav/pkgs/container/docker-webdav):

* _latest_ / _main_: the newest release.
* _YYYYMMDD_: a specific [release](https://github.com/moerchel/docker-webdav/releases), e.g. `20261107`. Further releases on the same day are numbered `20261107.1`, `20261107.2`, …
* _sha-xxxxxxx_: the image built from a specific commit.

The image is always based on the current Debian stable release (`debian:stable-slim`) with all package updates installed. It is rebuilt every Monday, so new Debian releases and security fixes are picked up automatically. Before an image is published, a smoke test checks the login, the WebDAV methods and the health check.

Releases are created automatically:

* for every change of the image on the `main` branch (changes to documentation only don't create a release),
* by the weekly rebuild every Monday, if Debian provides updated packages or a new release. The release notes list the updated packages. Without updates no new image and no release is published.

Old images are removed weekly from the registry: untagged images (old builds) and `sha-*` tags older than 30 days. Release images, _latest_ and _main_ are kept.

Every image is scanned with [Trivy](https://github.com/aquasecurity/trivy) before it is published. Builds with fixable HIGH or CRITICAL vulnerabilities are not published, all findings are listed in the repository's [Security tab](https://github.com/moerchel/docker-webdav/security/code-scanning).

## Build instructions

Clone this repo and then:

    cd docker-webdav
    docker build -t docker-webdav .

Or pull the prebuilt image:

    docker pull ghcr.io/moerchel/docker-webdav:latest

## How to run it

    docker run -d --name webdav --restart unless-stopped \
           -e USERNAME=webdav -e PASSWORD=secret \
           -v /srv/webdav/data:/media/data \
           -v /srv/webdav/logs:/media/logs \
           -p 8080:80 \
           ghcr.io/moerchel/docker-webdav:latest

The files are then available at `http://<host>:8080/`.

### Options

| Variable | Default | Description |
|---|---|---|
| `USERNAME`, `PASSWORD` | – | Login for one user. Without them (and without `HTPASSWD_FILE`) there is no login. |
| `HTPASSWD_FILE` | – | Path to an htpasswd file inside the container for several users, e.g. a mounted `/config/htpasswd`. Can't be combined with `USERNAME`/`PASSWORD`. |
| `PUID`, `PGID` | `33` | User and group ID that nginx uses to write files, e.g. your own user on the host (`id -u`, `id -g`). |
| `TRUSTED_PROXIES` | – | Addresses or networks of reverse proxies, separated by spaces or commas (e.g. `172.16.0.0/12`). Their `X-Forwarded-For` header is used as client address in the logs. Without it the header is ignored, so clients can't fake their address. |

The container stops with an error if an option has an invalid value.

An htpasswd file with several users can be created with `htpasswd` from the image:

    docker run --rm -it --entrypoint htpasswd ghcr.io/moerchel/docker-webdav:latest -nB alice >> htpasswd
    docker run -d --name webdav -e HTPASSWD_FILE=/config/htpasswd \
           -v "$PWD/htpasswd:/config/htpasswd:ro" -v /srv/webdav/data:/media/data -p 8080:80 \
           ghcr.io/moerchel/docker-webdav:latest

### Data and permissions

The files are stored in `/media/data`. New files and directories belong to `PUID`/`PGID`. If `/media/data` isn't writable for this user at start (e.g. a directory that Docker created as root), the container changes the owner of `/media/data` itself, not of the files in it.

### Logs

* `docker logs webdav` shows every request and nginx warnings and errors.
* `/media/logs/access.log` and `/media/logs/error.log` only get failed requests (status 4xx and 5xx) and errors. They are rotated daily and kept for 30 days.

### Health check

The image has a health check that requests `/health` (status 200, no login needed, not logged). `docker ps` shows the state as `healthy` or `unhealthy`. A file named `health` in the root directory can't be accessed because of this.

### Clients

* **Windows:** Explorer → "Map network drive" → `http://<host>:8080/`. For plain HTTP with login, Windows needs `BasicAuthLevel` = `2` in `HKLM\SYSTEM\CurrentControlSet\Services\WebClient\Parameters`.
* **macOS:** Finder → Go → Connect to Server → `http://<host>:8080/`.
* **Linux:** e.g. `davfs2`, Nautilus/Dolphin (`dav://<host>:8080/`) or `rclone`.

LOCK/UNLOCK is supported, so macOS and Windows can write files. Directories work with and without a trailing slash.

### docker compose

See [docker-compose/docker-compose.yml](docker-compose/docker-compose.yml): copy `.env.example` to `.env`, set `USERNAME` and `PASSWORD` there and start it with `docker compose up -d`. The example binds the port to `127.0.0.1` for a reverse proxy on the same host; use `"8080:80"` to make it reachable from the network.

## License

[MIT](LICENSE)
