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
AD_TAG="${AD_TAG:-}"

# Ambil IP internal container (buat nat-info)
LOCAL_IP=$(hostname -I | awk '{print $1}')

# Ambil IP publik Railway via metadata atau env
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
if [ -n "$AD_TAG" ]; then
    echo "[MTProxy] Ad Tag    : $AD_TAG"
else
    echo "[MTProxy] Ad Tag    : (tidak di-set, sponsored channel TIDAK akan muncul)"
fi
echo "[MTProxy] Local IP  : $LOCAL_IP"
echo "[MTProxy] Public IP : $PUBLIC_IP"
echo "[MTProxy] ============================================"

cd "$WORKDIR"

# Siapkan flag ad tag, kosong kalau AD_TAG belum di-set
ADTAG_FLAG=()
if [ -n "$AD_TAG" ]; then
    ADTAG_FLAG=(-P "$AD_TAG")
fi

if [ -n "$PUBLIC_IP" ] && [ -n "$LOCAL_IP" ] && [ "$PUBLIC_IP" != "$LOCAL_IP" ]; then
    echo "[MTProxy] Using NAT: $LOCAL_IP -> $PUBLIC_IP"
    exec ./objs/bin/mtproto-proxy \
        -u nobody \
        -p 8888 \
        -H "$PORT" \
        -S "$SECRET" \
        -M "$WORKERS" \
        "${ADTAG_FLAG[@]}" \
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
        "${ADTAG_FLAG[@]}" \
        --aes-pwd proxy-secret proxy-multi.conf
fi
