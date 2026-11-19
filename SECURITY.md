# Security policy

## Supported versions

Only the newest image is supported: `latest` and the newest release tag.
Older release tags are not updated. The image is rebuilt every 3 days
with the current Debian stable packages.

## Reporting a vulnerability

Please don't open a public issue. Report it privately via
**Security → Report a vulnerability** in this repository.

## Scope

In scope: the Dockerfile, entrypoint.sh, healthcheck.sh, the nginx and
logrotate configuration and the GitHub workflows of this repository.

Vulnerabilities in nginx or Debian itself should be reported upstream
(https://nginx.org/en/security_advisories.html,
https://www.debian.org/security/). Their fixes reach this image with the
next rebuild.
