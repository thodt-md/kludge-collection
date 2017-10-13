#!/bin/bash

CADDY_URL="https://caddyserver.com/download/linux/amd64"
CADDY_HOME=./.caddy
KEYS_DIR=./.caddy/keys

CERT_SUBJECT="/C=AU/ST=Some-State/O=Internet Widgits Pty Ltd/CN=localhost"
PROXY_PORT=8443
TARGET_PORT=8080

if [ ! -f "$CADDY_HOME/caddy" ]; then
  mkdir -p "$CADDY_HOME/tmp"
  if [ ! -f  "$CADDY_HOME/tmp/caddy.tar.gz" ]; then
    echo "Downloading Caddy"
    wget "$CADDY_URL" -O "$CADDY_HOME/tmp/caddy.tar.gz"
  fi
  echo "Unpacking Caddy"
  tar -xzf "$CADDY_HOME/tmp/caddy.tar.gz" -C "$CADDY_HOME" caddy
  echo "Removing temporary archive"
  rm -rf "$CADDY_HOME/tmp"
else
  echo "Caddy found"
fi

if [ -f "$KEYS_DIR/server.key" ] && [ -f "$KEYS_DIR/server.crt" ]; then
  echo "Key found"
else
  echo "Generating self-signed certificate"
  mkdir -p $KEYS_DIR
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "$KEYS_DIR/server.key" -out "$KEYS_DIR/server.crt" \
  -subj "$CERT_SUBJECT"
fi

if [ -n "$1" ]; then
  PROXY_PORT=$1
fi
echo "Will be listening on $PROXY_PORT"

if [ -n "$2" ]; then
  TARGET_PORT=$2
fi
echo "Will connect to $TARGET_PORT"

cd $CADDY_HOME

echo "Writing Caddyfile"
cat > "Caddyfile.$PROXY_PORT" << EOF
0.0.0.0:$PROXY_PORT {
  log stdout
  errors stderr
  tls ./keys/server.crt ./keys/server.key
  proxy / http://localhost:$TARGET_PORT {
    transparent
    header_upstream X-Forwarded-Port $PROXY_PORT
  }
}
EOF

./caddy -conf "Caddyfile.$PROXY_PORT"
