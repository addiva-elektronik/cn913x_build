export PKG_CONFIG_PATH=$ROOTDIR/build/musdk-marvell-SDK11.22.07/usr/local/lib/pkgconfig/:$PKG_CONFIG_PATH
cd $ROOTDIR/build/dpdk
meson build -Dexamples=all --cross-file $ROOTDIR/configs/dpdk/arm64_armada_solidrun_linux_gcc
ninja -C build

ROOTFS=$ROOTDIR/images/rootfs
mkdir -p $ROOTFS/root/dpdk
cp -p build/app/dpdk-testpmd $ROOTFS/root/dpdk/

