set -eux; \
	apt-get update; \
	apt-get install -y \
		bzip2 \
		curl \
		gcc \
		gnupg dirmngr \
		make \
		patch \
		bc \
		cpio \
		dpkg-dev \
		file \
		g++ \
		perl \
		python3 \
		rsync \
		unzip \
		wget \
	; \
	rm -rf /var/lib/apt/lists/*

gpg --batch --keyserver keyserver.ubuntu.com --recv-keys AB07D806D2CE741FB886EE50B025BA8B59C36319
BUILDROOT_VERSION=2022.02.8

set -eux; \
	tarball="buildroot-${BUILDROOT_VERSION}.tar.xz"; \
	curl -fL -o buildroot.tar.xz "https://buildroot.org/downloads/$tarball"; \
	curl -fL -o buildroot.tar.xz.sign "https://buildroot.org/downloads/$tarball.sign"; \
	gpg --batch --decrypt --output buildroot.tar.xz.txt buildroot.tar.xz.sign; \
	awk '$1 == "SHA1:" && $2 ~ /^[0-9a-f]+$/ && $3 == "'"$tarball"'" { print $2, "*buildroot.tar.xz" }' buildroot.tar.xz.txt > buildroot.tar.xz.sha1; \
	test -s buildroot.tar.xz.sha1; \
	sha1sum -c buildroot.tar.xz.sha1; \
	mkdir -p /usr/src/buildroot; \
	tar -xf buildroot.tar.xz -C /usr/src/buildroot --strip-components 1; \
	rm buildroot.tar.xz*

set -eux; \
	\
	cd /usr/src/buildroot; \
	\
	setConfs='
		BR2_STATIC_LIBS=y
		BR2_TOOLCHAIN_BUILDROOT_UCLIBC=y
	'; \
	\
	unsetConfs='
		BR2_SHARED_LIBS
	'; \
	\
	dpkgArch="$(dpkg --print-architecture)"; \
	case "$dpkgArch" in \
		amd64) \
			setConfs="$setConfs
				BR2_x86_64=y
			"; \
			;; \
			\
		arm64) \
			setConfs="$setConfs
				BR2_aarch64=y
			"; \
			;; \
			\
		armel) \
			setConfs="$setConfs
				BR2_arm=y
				BR2_arm926t=y
				BR2_ARM_EABI=y
				BR2_ARM_INSTRUCTIONS_THUMB=y
				BR2_ARM_SOFT_FLOAT=y
			"; \
			;; \
			\
		armhf) \
			setConfs="$setConfs
				BR2_arm=y
				BR2_cortex_a9=y
				BR2_ARM_EABIHF=y
				BR2_ARM_ENABLE_VFP=y
				BR2_ARM_FPU_VFPV3D16=y
				BR2_ARM_INSTRUCTIONS_THUMB2=y
			"; \
			unsetConfs="$unsetConfs BR2_ARM_SOFT_FLOAT"; \
			;; \
			\
		i386) \
			setConfs="$setConfs
				BR2_i386=y
			"; \
			;; \
			\
		mips64el) \
			setConfs="$setConfs
				BR2_mips64el=y
				BR2_mips_64r2=y
				BR2_MIPS_NABI64=y
			"; \
			unsetConfs="$unsetConfs
				BR2_MIPS_SOFT_FLOAT
			"; \
			;; \
			\
		riscv64) \
			setConfs="$setConfs
				BR2_riscv=y
				BR2_RISCV_64=y
			"; \
			;; \
			\
		*) \
			echo >&2 "Error: unsupported architecture '$dpkgArch'! Please use MUSL instead of UCLIBC."; \
			exit 1; \
			;; \
	esac; \
	if [ "$dpkgArch" != 'i386' ]; then \
		unsetConfs="$unsetConfs BR2_i386"; \
	fi; \
	\
	make defconfig; \
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
	make oldconfig < /dev/null; \
	\
	for conf in $unsetConfs; do \
		! grep -q "^$conf=" .config; \
	done; \
	for confV in $setConfs; do \
		grep -q "^$confV\$" .config; \
	done;

set -eux; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	make -C /usr/src/buildroot \
		HOST_GMP_CONF_OPTS="--build='"$gnuArch"'" \
		FORCE_UNSAFE_CONFIGURE=1 \
		-j "$(nproc)" \
		toolchain
PATH=/usr/src/buildroot/output/host/usr/bin:$PATH

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
	CROSS_COMPILE="$(basename /usr/src/buildroot/output/host/usr/*-buildroot-linux-uclibc*)"; \
	export CROSS_COMPILE="$CROSS_COMPILE-"; \
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
