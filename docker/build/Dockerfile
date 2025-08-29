FROM alpine
RUN apk add --no-cache iptables iptables-legacy tzdata
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
COPY zgx_natpierce.sh /version/zgx_natpierce.sh
RUN chmod +x /version/zgx_natpierce.sh
COPY iptables.sh /version/iptables.sh
RUN chmod +x /version/iptables.sh
ENV webdkh=33272
ENV update=true
ENV customversion=null
WORKDIR /natpierce
LABEL org.opencontainers.image.authors="XingHeYuZhuan"
LABEL org.opencontainers.image.source="https://github.com/natpierce/natpierce-docker"
CMD [ "/version/zgx_natpierce.sh" ]