# Busybox builder image (use MUSL for faster compilation time)
FROM alpine
USER root
COPY prepare_musl.sh /
RUN /prepare_musl.sh

# Busybox source directory
FROM busybox

# generate clean, final image for end users
FROM scratch
COPY --from=0 /usr/src/busybox/rootfs/. /
COPY --from=1 /etc/. /etc/
CMD ["./bin/sh"]
