echo "Building the kernel"
echo
cd $ROOTDIR/build/linux
make -j${PARALLEL} all #Image dtbs modules

ROOTFS=$ROOTDIR/images/linux-${KERNEL_RELEASE}
rm -rf $ROOTFS
mkdir -p $ROOTFS
mkdir -p $ROOTFS/boot
make INSTALL_MOD_PATH=$ROOTFS INSTALL_MOD_STRIP=1 modules_install
cp -p $ROOTDIR/build/linux/arch/arm64/boot/Image $ROOTFS/boot/
cp -p $ROOTDIR/build/linux/arch/arm64/boot/dts/marvell/cn913*.dtb $ROOTFS/boot/

