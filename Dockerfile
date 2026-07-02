FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/TelegramMessenger/MTProxy.git /opt/MTProxy \
    && cd /opt/MTProxy \
    && make -j$(nproc)

WORKDIR /opt/MTProxy

RUN curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf \
    && curl -s https://core.telegram.org/getProxySecret -o proxy-secret

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 443

ENTRYPOINT ["/entrypoint.sh"]
