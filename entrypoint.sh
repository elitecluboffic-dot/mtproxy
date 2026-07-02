#!/bin/bash
set -e

WORKDIR=/opt/MTProxy

echo "[MTProxy] Downloading latest Telegram proxy config..."
curl -s https://core.telegram.org/getProxyConfig -o "$WORKDIR/proxy-multi.conf" || true
curl -s https://core.telegram.org/getProxySecret  -o "$WORKDIR/proxy-secret"     || true

if [ -z "$SECRET" ]; then
    echo "[MTProxy] ERROR: Environment variable SECRET belum di-set!"
    exit 1
fi

PORT="${PORT:-443}"
WORKERS="${WORKERS:-2}"

echo "[MTProxy] ============================================"
echo "[MTProxy] Starting MTProxy..."
echo "[MTProxy] Port    : $PORT"
echo "[MTProxy] Workers : $WORKERS"
echo "[MTProxy] Secret  : $SECRET"
echo "[MTProxy] ============================================"

cd "$WORKDIR"

exec ./objs/bin/mtproto-proxy \
    -u nobody \
    -p 8888 \
    -H "$PORT" \
    -S "$SECRET" \
    -M "$WORKERS" \
    --aes-pwd proxy-secret proxy-multi.conf
