rm -rf $ROOTDIR/images
mkdir -p $ROOTDIR/images
mkdir -p $ROOTDIR/images/rootfs/usr/lib
ln -s usr/lib $ROOTDIR/images/rootfs/
