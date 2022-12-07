echo "Assembling rootfs image"
echo

cd $ROOTDIR/images
release=$(cat kernel_release)

ROOTFS=$ROOTDIR/images/rootfs
# blkid images/tmp/ubuntu-core.img | cut -f2 -d'"'
mkdir -p $ROOTDIR/images/tmp/
ROOTIMG=$ROOTDIR/images/tmp/ubuntu-core.ext4
rm -f $ROOTIMG
cp $ROOTDIR/build/ubuntu-core.ext4 $ROOTIMG


cd $ROOTFS
for i in `find .`; do
        if [ -d $i ]; then
                e2mkdir -G 0 -O 0 $ROOTIMG:$i
        fi
        if [ -f $i ]; then
                e2cp -G 0 -O 0 -p $i $ROOTIMG:$i
        fi
done
cd -

mv $ROOTDIR/images/tmp/ubuntu-core.ext4  $ROOTDIR/images/ubuntu-$release.ext4
