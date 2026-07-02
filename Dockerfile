FROM alpine:3.18

RUN apk add --no-cache \
    git \
    build-base \
    openssl-dev \
    linux-headers \
    curl \
    bash

RUN git clone https://github.com/TelegramMessenger/MTProxy.git /opt/MTProxy \
    && cd /opt/MTProxy \
    && make -j$(nproc)

WORKDIR /opt/MTProxy

# Download config Telegram terbaru waktu build
RUN curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf \
    && curl -s https://core.telegram.org/getProxySecret -o proxy-secret

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 443

ENTRYPOINT ["/entrypoint.sh"]
