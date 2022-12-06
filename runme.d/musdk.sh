if [[ ! -d $ROOTDIR/build/musdk-marvell-SDK11.22.07 ]]; then
	cd $ROOTDIR/build/
	wget https://solidrun-common.sos-de-fra-1.exo.io/cn913x/marvell/SDK11.22.07/sources-musdk-marvell-SDK11.22.07.tar.bz2
	tar -vxf sources-musdk-marvell-SDK11.22.07.tar.bz2
	rm -f sources-musdk-marvell-SDK11.22.07.tar.bz2
	cd musdk-marvell-SDK11.22.07
	patch -p1 < $ROOTDIR/patches/musdk/*.patch
fi

cd $ROOTDIR/build/musdk-marvell-SDK11.22.07
./bootstrap
./configure --host=aarch64-linux-gnu
make -j${PARALLEL}
make install
cd $ROOTDIR/build/musdk-marvell-SDK11.22.07/modules/cma
make -j${PARALLEL} -C "$ROOTDIR/build/linux" M="$PWD" modules
cd $ROOTDIR/build/musdk-marvell-SDK11.22.07/modules/pp2
make -j${PARALLEL} -C "$ROOTDIR/build/linux" M="$PWD" modules

