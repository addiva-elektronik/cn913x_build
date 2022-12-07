echo "Building the kernel"
echo
cd $ROOTDIR/build/linux
make -j${PARALLEL} all #Image dtbs modules

ROOTFS=$ROOTDIR/images/rootfs
mkdir -p $ROOTFS/boot
release=$(make kernelrelease)
make INSTALL_MOD_PATH=$ROOTFS INSTALL_MOD_STRIP=1 modules_install
cp -p $ROOTDIR/build/linux/arch/arm64/boot/Image $ROOTFS/boot/linux-$release
echo $release > $ROOTDIR/images/kernel_release
mkdir -p $ROOTFS/boot/marvell/
cp -p $ROOTDIR/build/linux/arch/arm64/boot/dts/marvell/cn913*.dtb $ROOTFS/boot/marvell/
