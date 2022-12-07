#!/bin/bash
set -e
#set -x

# BOOT_LOADER=u-boot
# CPU_SPEED=1600,2000,2200
# SERDES=0
# CP_NUM=1,2,3
###############################################################################
# General configurations
###############################################################################
#RELEASE=cn9130-early-access-bsp_rev1.0 # Supports both rev1.0 and rev1.1
BUILDROOT_VERSION=2020.02.1
: ${BR2_PRIMARY_SITE:=} # custom buildroot mirror
#UEFI_RELEASE=DEBUG
#BOOT_LOADER=uefi
#DDR_SPEED=2400
#BOARD_CONFIG -
# 0-clearfog_cn COM express
# 1-clearfog-base (cn9130 SOM)
# 2-clearfog-pro (cn9130 SOM)
# 3-SolidWAN (cn9130 SOM)
# 4-BlDN MBV-A/B (cn9130 SOM)


#UBOOT_ENVIRONMENT -
# - spi (SPI FLash)
# - mmc:0:0 (MMC 0 Data area)
# - mmc:0:1 (MMC 0 boot0)
# - mmc:0:2 (MMC 0 boot1)
# - mmc:1:0 (MMC 1 Data area) <-- default, microSD on Clearfog
# - mmc:1:1 (MMC 1 boot0)
# - mmc:1:2 (MMC 1 boot1)
: ${UBOOT_ENVIRONMENT:=mmc:1:0} # default microSD partition 0

: ${BUILD_ROOTFS:=yes} # set to no for bootloader-only build

# Ubuntu Version
# - bionic (18.04)
# - focal (20.04)
# or numeric version
: ${UBUNTU_VERSION:=focal}

# Check if git user name and git email are configured
if [ -z "`git config user.name`" ] || [ -z "`git config user.email`" ]; then
			echo "git is not configured, please run:"
			echo "git config --global user.email \"you@example.com\""
			echo "git config --global user.name \"Your Name\""
			exit -1
fi

###############################################################################
# Misc
###############################################################################

KERNEL_RELEASE=${KERNEL_RELEAE:-v5.15}
DPDK_RELEASE=${DPDK_RELEASE:-v22.07}

SHALLOW=${SHALLOW:true}
if [ "x$SHALLOW" == "xtrue" ]; then
	SHALLOW_FLAG="--depth 1"
fi
BOOT_LOADER=${BOOT_LOADER:-u-boot}
BOARD_CONFIG=${BOARD_CONFIG:-0}
CP_NUM=${CP_NUM:-3}
mkdir -p build images
ROOTDIR=`pwd`
PARALLEL=$(getconf _NPROCESSORS_ONLN) # Amount of parallel jobs for the builds
TOOLS="wget tar git make 7z unsquashfs dd vim mkfs.ext4 parted mkdosfs mcopy dtc iasl mkimage e2cp truncate qemu-system-aarch64 cpio rsync bc bison flex python unzip"

export PATH=$ROOTDIR/build/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin:$PATH
export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

case "${BOARD_CONFIG}" in
	0)
		echo "*** Board Configuration CEx7 CN9132 based on Clearfog CN9K ***"
		if [ "x$CP_NUM" == "x1" ]; then
			DTB_UBOOT=cn9130-cex7-A
			DTB_KERNEL=cn9130-cex7
		elif [ "x$CP_NUM" == "x2" ]; then
			DTB_UBOOT=cn9131-cex7-A
			DTB_KERNEL=cn9131-cex7
		elif [ "x$CP_NUM" == "x3" ]; then
                        DTB_UBOOT=cn9132-cex7-A
			DTB_KERNEL=cn9132-cex7
		else 
			 echo "Please define a correct number of CPs [1,2,3]"
			 exit -1
		fi
	;;
	1)
                echo "*** CN9130 SOM based on Clearfog Base ***"
		CP_NUM=1
		DTB_UBOOT=cn9130-cf-base
		DTB_KERNEL=cn9130-cf-base
	;;
	2)
		echo "*** CN9130 SOM based on Clearfog Pro ***"
		CP_NUM=1
		DTB_UBOOT=cn9130-cf-pro
                DTB_KERNEL=cn9130-cf-pro
	;;

	3)
		echo "*** CN9131 SOM based on SolidWAN ***"
		CP_NUM=2
		DTB_UBOOT=cn9131-cf-solidwan
		DTB_KERNEL=cn9131-cf-solidwan
	;;
	4) 	
		echo "*** CN9131 SOM based on Bldn MBV-A/B ***"
                CP_NUM=2
                DTB_UBOOT=cn9131-bldn-mbv
                DTB_KERNEL=cn9131-bldn-mbv
        ;;


	*)
		echo "Please define board configuration"
		exit -1
	;;
esac

x() {
	( . runme.d/$1.sh )
}

#########################
# Build image
#########################

if [ $# -ge 1 ]; then

	for step; do
		x $step
	done
	exit
fi

# Default sequence

x tools

x sources

x ubuntu

x newbuild

x u-boot

x linux-config

x linux

if [ "x${BUILD_ROOTFS}" != "xyes" ]; then
	echo "U-Boot Ready, Skipping RootFS"
	exit 0
fi

# musdk

# dpdk

x rootfs

x sdcard
