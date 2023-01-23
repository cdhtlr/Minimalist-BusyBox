set -eux; \
	apk add --no-cache \
		bzip2 \
		coreutils \
		curl \
		gcc \
		gnupg \
		linux-headers \
		make \
		musl-dev \
		patch \
		tzdata \
	;

gpg --batch --keyserver keyserver.ubuntu.com --recv-keys C9E9416F76E610DBD09D040F47B70C55ACC9965B

BUSYBOX_VERSION=1.36.0

set -eux; \
	tarball="busybox-${BUSYBOX_VERSION}.tar.bz2"; \
	curl -fL -o busybox.tar.bz2.sig "https://busybox.net/downloads/$tarball.sig"; \
	curl -fL -o busybox.tar.bz2 "https://busybox.net/downloads/$tarball"; \
	mkdir -p /usr/src/busybox; \
	tar -xf busybox.tar.bz2 -C /usr/src/busybox --strip-components 1; \
	rm busybox.tar.bz2*

cd /usr/src/busybox

set -eux; \
	\
	setConfs='
		CONFIG_STATIC=y
		CONFIG_LFS=y
		CONFIG_CLEAR=y
		CONFIG_WATCH=y
		CONFIG_IFCONFIG=y
		CONFIG_UDHCPC=y
		CONFIG_PING=y
		CONFIG_TELNETD=y
		CONFIG_TRACEROUTE=y
		CONFIG_ASH_OPTIMIZE_FOR_SIZE=y
		CONFIG_ASH_INTERNAL_GLOB=y
		CONFIG_FEATURE_SH_EMBEDDED_SCRIPTS=y
		CONFIG_FEATURE_SYSLOG_INFO=y
		CONFIG_FEATURE_SYSLOG=y
		CONFIG_FEATURE_ETC_NETWORKS=y
		CONFIG_FEATURE_HWIB=y
		CONFIG_FEATURE_IFCONFIG_STATUS=y
		CONFIG_FEATURE_IFCONFIG_SLIP=y
		CONFIG_FEATURE_IFCONFIG_MEMSTART_IOADDR_IRQ=y
		CONFIG_FEATURE_IFCONFIG_HW=y
		CONFIG_FEATURE_IFCONFIG_BROADCAST_PLUS=y
		CONFIG_NOLOGIN=y
		CONFIG_FEATURE_UDHCPC_ARPING=y
		CONFIG_FEATURE_UDHCPC_SANITIZEOPT=y
		CONFIG_UDHCPC_DEFAULT_SCRIPT="/usr/share/udhcpc/default.script"
		CONFIG_UDHCPC_DEFAULT_INTERFACE="eth0"
		CONFIG_UDHCP_DEBUG=2
		CONFIG_UDHCPC_SLACK_FOR_BUGGY_SERVERS=80
		CONFIG_FEATURE_UDHCP_RFC3397=y
		CONFIG_FEATURE_UDHCP_8021Q=y
		CONFIG_FEATURE_FANCY_PING=y
		CONFIG_FEATURE_TELNETD_STANDALONE=y
		CONFIG_FEATURE_TELNETD_PORT_DEFAULT=23
		CONFIG_FEATURE_TELNETD_INETD_WAIT=y
		CONFIG_FEATURE_TRACEROUTE_VERBOSE=y
		CONFIG_FEATURE_TRACEROUTE_USE_ICMP=y
	'; \
	\
	unsetConfs='
		CONFIG_SH_IS_HUSH
		CONFIG_BASH_IS_HUSH
	'; \
	\
	make allnoconfig; \
	\
	for conf in $unsetConfs; do \
		sed -i \
			-e "s!^$conf=.*\$!# $conf is not set!" \
			.config; \
	done; \
	\
	for confV in $setConfs; do \
		conf="${confV%=*}"; \
		sed -i \
			-e "s!^$conf=.*\$!$confV!" \
			-e "s!^# $conf is not set\$!$confV!" \
			.config; \
		if ! grep -q "^$confV\$" .config; then \
			echo "$confV" >> .config; \
		fi; \
	done; \
	\
	make oldconfig < /dev/null ; \
	\
	for conf in $unsetConfs; do \
		! grep -q "^$conf=" .config; \
	done; \
	for confV in $setConfs; do \
		grep -q "^$confV\$" .config; \
	done

set -eux; \
	nproc="$(nproc)"; \
	make -j "$nproc" busybox; \
	mkdir -p rootfs/bin; \
	ln -vL busybox rootfs/bin/; \
	ln -s busybox rootfs/bin/sh; \
	ln -s busybox rootfs/bin/clear; \
	ln -s busybox rootfs/bin/watch; \
	ln -s busybox rootfs/bin/ifconfig; \
	ln -s busybox rootfs/bin/udhcpc; \
	ln -s busybox rootfs/bin/ping; \
	ln -s busybox rootfs/bin/telnetd; \
	ln -s busybox rootfs/bin/traceroute; \
	echo >&2 "Finished: Successfully created Busybox."; \
	exit 0
