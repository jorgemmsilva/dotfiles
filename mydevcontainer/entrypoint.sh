#!/bin/sh
# Fix Docker socket permissions if mounted, then drop to dev user
if [ -S /var/run/docker.sock ]; then
    chmod 666 /var/run/docker.sock
fi

export HOME=/home/dev
exec setpriv --reuid=dev --regid=dev --init-groups -- "$@"
