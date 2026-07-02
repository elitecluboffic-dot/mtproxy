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

# Ambil IP internal container (buat nat-info)
LOCAL_IP=$(hostname -I | awk '{print $1}')

# Ambil IP publik Railway via metadata atau env
# Kalau RAILWAY_PUBLIC_DOMAIN ada, resolve IP-nya
if [ -n "$RAILWAY_PUBLIC_DOMAIN" ]; then
    PUBLIC_IP=$(getent hosts "$RAILWAY_PUBLIC_DOMAIN" | awk '{print $1}' | head -1)
else
    PUBLIC_IP=$(curl -s https://api.ipify.org 2>/dev/null || echo "")
fi

echo "[MTProxy] ============================================"
echo "[MTProxy] Starting MTProxy..."
echo "[MTProxy] Port      : $PORT"
echo "[MTProxy] Workers   : $WORKERS"
echo "[MTProxy] Secret    : $SECRET"
echo "[MTProxy] Local IP  : $LOCAL_IP"
echo "[MTProxy] Public IP : $PUBLIC_IP"
echo "[MTProxy] ============================================"

cd "$WORKDIR"

if [ -n "$PUBLIC_IP" ] && [ -n "$LOCAL_IP" ] && [ "$PUBLIC_IP" != "$LOCAL_IP" ]; then
    echo "[MTProxy] Using NAT: $LOCAL_IP -> $PUBLIC_IP"
    exec ./objs/bin/mtproto-proxy \
        -u nobody \
        -p 8888 \
        -H "$PORT" \
        -S "$SECRET" \
        -M "$WORKERS" \
        --nat-info "$LOCAL_IP:$PUBLIC_IP" \
        --aes-pwd proxy-secret proxy-multi.conf
else
    echo "[MTProxy] No NAT detected, running without nat-info"
    exec ./objs/bin/mtproto-proxy \
        -u nobody \
        -p 8888 \
        -H "$PORT" \
        -S "$SECRET" \
        -M "$WORKERS" \
        --aes-pwd proxy-secret proxy-multi.conf
fi
