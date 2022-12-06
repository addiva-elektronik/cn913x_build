echo "Assembling rootfs image"
echo

cd $ROOTDIR/images

KERNELROOT=$ROOTDIR/images/linux-${KERNEL_RELEASE}
# blkid images/tmp/ubuntu-core.img | cut -f2 -d'"'
mkdir -p $ROOTDIR/images/tmp/
rm -f $ROOTDIR/images/tmp/ubuntu-core.ext4
cp $ROOTDIR/build/ubuntu-core.ext4 $ROOTDIR/images/tmp/
e2mkdir -G 0 -O 0 $ROOTDIR/images/tmp/ubuntu-core.ext4:boot
e2cp -G 0 -O 0 $KERNELROOT/boot/Image $ROOTDIR/images/tmp/ubuntu-core.ext4:boot/
e2mkdir -G 0 -O 0 $ROOTDIR/images/tmp/ubuntu-core.ext4:boot/marvell
e2cp -G 0 -O 0 $KERNELROOT/boot/*.dtb $ROOTDIR/images/tmp/ubuntu-core.ext4:boot/marvell/

# Copy DPDK testpmd
e2mkdir -G 0 -O 0 $ROOTDIR/images/tmp/ubuntu-core.ext4:root/dpdk
e2cp -G 0 -O 0 -p $ROOTDIR/build/dpdk/build/app/dpdk-testpmd $ROOTDIR/images/tmp/ubuntu-core.ext4:root/dpdk/

# Copy MUSDK
cd $ROOTDIR/build/musdk-marvell-SDK11.22.07/usr/local/
for i in `find .`; do
	if [ -d $i ]; then
		e2mkdir -v -G 0 -O 0 $ROOTDIR/images/tmp/ubuntu-core.ext4:usr/$i
	fi
	if [ -f $i ] && ! [ -L $i ]; then
		DIR=`dirname $i`
		e2cp -v -G 0 -O 0 -p $ROOTDIR/build/musdk-marvell-SDK11.22.07/usr/local/$i $ROOTDIR/images/tmp/ubuntu-core.ext4:usr/$DIR
	fi
done
for i in `find .`; do
	if [ -L $i ]; then
		DIR=`dirname $i`
		DEST=`readlink -qn $i`
		e2ln -vf $ROOTDIR/images/tmp/ubuntu-core.ext4:usr/$DIR/$DEST /usr/$i
	fi
done
cd -

# Copy over kernel image
echo
echo "Copying kernel modules"
echo
cd $KERNELROOT
for i in `find lib/modules`; do
        if [ -d $i ]; then
                e2mkdir -G 0 -O 0 $ROOTDIR/images/tmp/ubuntu-core.ext4:$i
        fi
        if [ -f $i ]; then
                e2cp -G 0 -O 0 -p $i $ROOTDIR/images/tmp/ubuntu-core.ext4:$i
        fi
done
cd -

# Copy MUSDK modules
e2mkdir -G 0 -O 0 $ROOTDIR/images/tmp/ubuntu-core.ext4:root/musdk_modules
e2cp -G 0 -O 0 $ROOTDIR/build/musdk-marvell-SDK11.22.07/modules/cma/musdk_cma.ko $ROOTDIR/images/tmp/ubuntu-core.ext4:root/musdk_modules
e2cp -G 0 -O 0 $ROOTDIR/build/musdk-marvell-SDK11.22.07/modules/pp2/mv_pp_uio.ko $ROOTDIR/images/tmp/ubuntu-core.ext4:root/musdk_modules

mv $ROOTDIR/images/tmp/ubuntu-core.ext4  $ROOTDIR/images/ubuntu-${DTB_KERNEL}-${KERNEL_RELEASE}.ext4
