#!/bin/bash

if [ $# -ne 2 ]; then
    echo "usage: $0 <listen port> <unix socket file>"
    exit
fi

PORT=$1
SOCK=$2

socat -d -d -d -lf ns-socat.log TCP-LISTEN:${PORT},reuseaddr,fork UNIX-CLIENT:${SOCK}
