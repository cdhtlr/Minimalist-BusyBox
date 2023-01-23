# Minimalist networking-only BusyBox image

**Minimalist networking-only BusyBox image** using musl C standard library (https://hub.docker.com/r/cdhtlr/busybox)

This Busybox image contains basic network commands consisting of ping, ifconfig and traceroute. 

You can use this image as a virtual PC in GNS3 or as a base image for Golang based applications such as the MikroTik-Speedtest image.

    Using ash as the default shell.
    DHCP client and Telnet server installed.
    Two additional commands outside of networking (clear and watch).

**Why don't I use Scratch or regular BusyBox?**

Scratch is an empty image whereas to run in a GNS3 environment, a docker appliance must have at least a shell, DHCP client, telnet server and ifconfig with the /etc directory and its contents.

I can use the regular BusyBox but there are too many tools/applets in it so I created a new BusyBox which is smaller in size which can still run in various environments.

This image only contains basic network tools with IPv4 support without SSL certificate so I do not recommend using this image as a container for applications that require IPv6, SSL certificates and debugging.

If you want something more than what this image provides then you can compile BusyBox yourself with the files I provide in my GitHub repository.

**Buildx command:**

    docker buildx build --platform linux/s390x,linux/ppc64le,linux/arm/v6,linux/arm/v7,linux/arm64,linux/386,linux/amd64,linux/amd64/v2,linux/amd64/v3 -t cdhtlr/busybox:latest --push .

This Docker Image is modified from <a href="https://github.com/dmitry-j-mikhin/busybox-docker">dmitry-j-mikhin's BusyBox Docker</a>
