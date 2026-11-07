#!/bin/bash
# Health check: nginx must answer /health with status 200.
exec 3<>/dev/tcp/127.0.0.1/80 || exit 1
printf 'GET /health HTTP/1.0\r\nHost: localhost\r\n\r\n' >&3
IFS= read -r -t 5 status <&3 || exit 1
[[ $status == "HTTP/1."?" 200 "* ]]
