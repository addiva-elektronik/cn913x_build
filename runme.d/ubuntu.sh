if [[ ! -f $ROOTDIR/binaries/ubuntu-core.ext4 ]]; then
	if [[ $UBUNTU_VERSION == bionic ]]; then
		UBUNTU_BASE_URL=http://cdimage.ubuntu.com/ubuntu-base/releases/18.04/release/ubuntu-base-18.04.5-base-arm64.tar.gz
	fi
	if [[ $UBUNTU_VERSION == focal ]]; then
		UBUNTU_BASE_URL=http://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.5-base-arm64.tar.gz
	fi
	if [[ -z $UBUNTU_BASE_URL ]]; then
		echo "Error: Unknown URL for Ubuntu Version \"\${UBUNTU_VERSION}! Please provide UBUNTU_BASE_URL."
		exit 1
	fi

        echo "Building Ubuntu ${UBUNTU_VERSION} File System"
	cd $ROOTDIR/build
        mkdir -p ubuntu
        cd ubuntu
	if [ ! -d buildroot ]; then
                git clone $SHALLOW_FLAG https://github.com/buildroot/buildroot -b $BUILDROOT_VERSION
        fi
	cd buildroot	
	cp $ROOTDIR/configs/buildroot/buildroot_defconfig configs/
	printf 'BR2_PRIMARY_SITE="%s"\n' "${BR2_PRIMARY_SITE}" >> configs/buildroot_defconfig
	make buildroot_defconfig 
	mkdir -p overlay/etc/init.d/
	cat > overlay/etc/init.d/S99bootstrap-ubuntu.sh << EOF
#!/bin/sh

case "\$1" in
        start)
		resize
                mkfs.ext4 -F /dev/vda -b 4096
                mount /dev/vda /mnt
                cd /mnt/
                udhcpc -i eth0
		wget -c -P /tmp/ -O /tmp/ubuntu-base.dl "${UBUNTU_BASE_URL}"
		tar -C /mnt -xf /tmp/ubuntu-base.dl
                mount -o bind /proc /mnt/proc/
                mount -o bind /sys/ /mnt/sys/
                mount -o bind /dev/ /mnt/dev/
                mount -o bind /dev/pts /mnt/dev/pts
                mount -t tmpfs tmpfs /mnt/var/lib/apt/
                mount -t tmpfs tmpfs /mnt/var/cache/apt/
                echo "nameserver 8.8.8.8" > /mnt/etc/resolv.conf
                echo "localhost" > /mnt/etc/hostname
                echo "127.0.0.1 localhost" > /mnt/etc/hosts
                export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C
                chroot /mnt apt update
                chroot /mnt apt install --no-install-recommends -y systemd-sysv apt locales less wget procps openssh-server ifupdown net-tools isc-dhcp-client ntpdate lm-sensors i2c-tools psmisc less sudo htop iproute2 iputils-ping kmod network-manager iptables rng-tools apt-utils libatomic1 ethtool
		echo -e "root\nroot" | chroot /mnt passwd
                umount /mnt/var/lib/apt/
                umount /mnt/var/cache/apt
                chroot /mnt apt clean
                chroot /mnt apt autoclean
                reboot
                ;;

esac
EOF

	chmod +x overlay/etc/init.d/S99bootstrap-ubuntu.sh
	make
	IMG=ubuntu-core.ext4.tmp
	truncate -s 450M $IMG
	qemu-system-aarch64 -m 1G -M virt -cpu cortex-a57 -nographic -smp 1 -kernel output/images/Image -append "console=ttyAMA0" -netdev user,id=eth0 -device virtio-net-device,netdev=eth0 -initrd output/images/rootfs.cpio.gz -drive file=$IMG,if=none,format=raw,id=hd0 -device virtio-blk-device,drive=hd0 -no-reboot
        mv $IMG $ROOTDIR/binaries/ubuntu-core.ext4

	cp output/images/rootfs.cpio.gz $ROOTDIR/binaries/rescuefs.cpio.gz
fi


