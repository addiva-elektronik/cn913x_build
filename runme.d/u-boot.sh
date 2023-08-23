echo "Building u-boot"
cd $ROOTDIR/build/u-boot/
cp configs/sr_cn913x_cex7_defconfig .config
[[ "${UBOOT_ENVIRONMENT}" =~ (.*):(.*):(.*) ]] || [[ "${UBOOT_ENVIRONMENT}" =~ (.*) ]]
if [ "x${BASH_REMATCH[1]}" = "xspi" ]; then
cat >> .config << EOF
CONFIG_ENV_IS_IN_MMC=n
CONFIG_ENV_IS_IN_SPI_FLASH=y
CONFIG_ENV_SIZE=0x10000
CONFIG_ENV_OFFSET=0x3f0000
CONFIG_ENV_SECT_SIZE=0x10000
EOF
elif [ "x${BASH_REMATCH[1]}" = "xmmc" ]; then
cat >> .config << EOF
CONFIG_ENV_IS_IN_MMC=y
CONFIG_SYS_MMC_ENV_DEV=${BASH_REMATCH[2]}
CONFIG_SYS_MMC_ENV_PART=${BASH_REMATCH[3]}
CONFIG_ENV_IS_IN_SPI_FLASH=n
EOF
else
	echo "ERROR: \$UBOOT_ENVIRONMENT setting invalid"
	exit 1
fi
make olddefconfig
make -j${PARALLEL} DEVICE_TREE=$DTB_UBOOT
cp $ROOTDIR/build/u-boot/u-boot.bin $ROOTDIR/images/u-boot.bin
install -m644 -D $ROOTDIR/build/u-boot/u-boot.bin $ROOTDIR/images/u-boot.bin

export BL33=$ROOTDIR/images/u-boot.bin

if [ "x$BOOT_LOADER" == "xuefi" ]; then
	echo "no support for uefi yet"
fi

echo "Building arm-trusted-firmware"
cd $ROOTDIR/build/arm-trusted-firmware
export SCP_BL2=$ROOTDIR/binaries/atf/mrvl_scp_bl2.img

echo "Compiling U-BOOT and ATF"
echo "CP_NUM=$CP_NUM"
echo "DTB=$DTB_UBOOT"

make PLAT=t9130 clean
make -j${PARALLEL} USE_COHERENT_MEM=0 LOG_LEVEL=20 PLAT=t9130 MV_DDR_PATH=$ROOTDIR/build/mv-ddr-marvell CP_NUM=$CP_NUM all fip

echo "Copying boot image to /Images folder"
cp $ROOTDIR/build/arm-trusted-firmware/build/t9130/release/flash-image.bin $ROOTDIR/images/boot-${DTB_UBOOT}-${UBOOT_ENVIRONMENT}.bin
