###############################################################################
# source code cloning and building 
###############################################################################

SDK_COMPONENTS="u-boot mv-ddr-marvell arm-trusted-firmware linux dpdk"

for i in $SDK_COMPONENTS; do
	if [[ ! -d $ROOTDIR/build/$i ]]; then
		if [ "x$i" == "xlinux" ]; then
			url=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
			echo "Cloing $url release $RELEASE"
			cd $ROOTDIR/build
			git clone $SHALLOW_FLAG $url linux -b $RELEASE
		elif [ "x$i" == "xarm-trusted-firmware" ]; then
			echo "Cloning atf from mainline"
			cd $ROOTDIR/build
			git clone https://github.com/ARM-software/arm-trusted-firmware.git arm-trusted-firmware
			cd arm-trusted-firmware
			# Temporary commit waiting for a release
			git checkout 00ad74c7afe67b2ffaf08300710f18d3dafebb45
		elif [ "x$i" == "xmv-ddr-marvell" ]; then
			echo "Cloning mv-ddr-marvell from mainline"
			echo "Cloing https://github.com/MarvellEmbeddedProcessors/mv-ddr-marvell.git"
			cd $ROOTDIR/build
			git clone https://github.com/MarvellEmbeddedProcessors/mv-ddr-marvell.git mv-ddr-marvell
			cd mv-ddr-marvell
			git checkout mv-ddr-devel
		elif [ "x$i" == "xu-boot" ]; then
			echo "Cloning u-boot from git://git.denx.de/u-boot.git"
			cd $ROOTDIR/build
			git clone git://git.denx.de/u-boot.git u-boot
			cd u-boot
			git checkout v2019.10 -b marvell
		elif [ "x$i" == "xdpdk" ]; then
                        echo "Cloning DPDK from https://github.com/DPDK/dpdk.git"
                        cd $ROOTDIR/build
                        git clone $SHALLOW_FLAG https://github.com/DPDK/dpdk.git dpdk -b $DPDK_RELEASE
			# Apply release specific DPDK patches
			if [ -d $ROOTDIR/patches/dpdk-$DPDK_RELEASE ]; then
				cd dpdk
				git am $ROOTDIR/patches/dpdk-${DPDK_RELEASE}/*.patch
			fi
		fi

		echo "Checking patches for $i"
		cd $ROOTDIR/build/$i
		if [ -d $ROOTDIR/patches/$i ]; then
			git am $ROOTDIR/patches/$i/*.patch
		fi
	fi
done
