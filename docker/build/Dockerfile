FROM alpine:latest

ENV webdkh=33272 \
    update=true \
    customversion=null

LABEL org.opencontainers.image.authors="XingHeYuZhuan" \
      org.opencontainers.image.source="https://github.com/natpierce/natpierce-docker"

WORKDIR /natpierce

RUN apk add --no-cache iptables iptables-legacy tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    rm -rf /var/cache/apk/*

COPY zgx_natpierce.sh iptables.sh update_parser.sh /version/

RUN chmod +x /version/zgx_natpierce.sh /version/iptables.sh  /version/update_parser.sh

CMD [ "/version/zgx_natpierce.sh" ]