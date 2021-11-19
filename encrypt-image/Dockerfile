FROM quay.io/buildah/stable

RUN dnf update -y && dnf install -y \
    cpio \
    cryptsetup \
    findutils \
    && rm -rf /var/cache /var/log/dnf* /var/log/yum.*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
