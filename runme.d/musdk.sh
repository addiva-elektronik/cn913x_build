if [[ ! -d $ROOTDIR/build/musdk-marvell-SDK11.22.07 ]]; then
	cd $ROOTDIR/build/
	wget https://solidrun-common.sos-de-fra-1.exo.io/cn913x/marvell/SDK11.22.07/sources-musdk-marvell-SDK11.22.07.tar.bz2
	tar -vxf sources-musdk-marvell-SDK11.22.07.tar.bz2
	rm -f sources-musdk-marvell-SDK11.22.07.tar.bz2
	cd musdk-marvell-SDK11.22.07
	git init .
	git add .
	git commit -m "musdk-marvell-SDK11.22.07"
	for patch in $ROOTDIR/patches/musdk/*.patch; do
	    git apply --index -p1 $patch
	    git commit -m $(basename $patch .patch)
	done
fi

cd $ROOTDIR/build/musdk-marvell-SDK11.22.07
./bootstrap
./configure --host=aarch64-linux-gnu CFLAGS="-fPIC -O2"
make -j${PARALLEL}
make install
cd $ROOTDIR/build/musdk-marvell-SDK11.22.07/modules/cma
make -j${PARALLEL} -C "$ROOTDIR/build/linux" M="$PWD" modules
cd $ROOTDIR/build/musdk-marvell-SDK11.22.07/modules/pp2
make -j${PARALLEL} -C "$ROOTDIR/build/linux" M="$PWD" modules


ROOTFS=$ROOTDIR/images/rootfs
mkdir -p $ROOTFS/usr/local
cp -rp $ROOTDIR/build/musdk-marvell-SDK11.22.07/usr/local/. $ROOTFS/usr/local/

# Copy MUSDK modules
mkdir -p $ROOTFS/root/musdk_modules
cp -p $ROOTDIR/build/musdk-marvell-SDK11.22.07/modules/cma/musdk_cma.ko $ROOTFS/root/musdk_modules/
cp -p $ROOTDIR/build/musdk-marvell-SDK11.22.07/modules/pp2/mv_pp_uio.ko $ROOTFS/root/musdk_modules/
