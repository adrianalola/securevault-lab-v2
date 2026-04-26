FROM alpine:3.19

RUN apk add --no-cache \
    openssh \
    tshark \
    curl \
    iputils

RUN adduser -D -s /bin/sh bastionuser && \
    passwd -u bastionuser

RUN mkdir -p /etc/ssh/authorized_keys && \
    ssh-keygen -A

COPY sshd_config /etc/ssh/sshd_config
COPY authorized_keys /etc/ssh/authorized_keys/bastionuser

RUN chmod 600 /etc/ssh/authorized_keys/bastionuser && \
    chown bastionuser:bastionuser /etc/ssh/authorized_keys/bastionuser

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D", "-e"]
