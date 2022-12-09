echo
echo "Assembling rescue image"
echo

cd $ROOTDIR/images
release=$(cat kernel_release)
rm -rf rescuefs tmp/rescuefs.cpio.gz
mkdir -p rescuefs
mkdir -p tmp

fakeroot bash -e -c "
cd rescuefs
zcat $ROOTDIR/binaries/rescuefs.cpio.gz | cpio -i
rm -rf lib/modules/*
rm -f etc/init.d/S99bootstrap-ubuntu.sh
cd ../rootfs
find lib/modules/* -depth -print0 |cpio -0pdm ../rescuefs/
cd ../rescuefs
cat <<EOF >> etc/network/interfaces

auto eth1
iface eth1 inet dhcp
	udhcpc_opts -b
        hostname $(hostname)

EOF

# Pack the initramfs
find . -print0 |cpio -0 -o -H newc | gzip -9 > ../tmp/initramfs.cpio.gz
"
mkdir -p rescue
mv tmp/initramfs.cpio.gz rescue/initramfs-$release.cpio.gz
cat > tmp/extlinux.conf << EOF
  TIMEOUT 30
  DEFAULT $release
  MENU TITLE linux-cn913x boot options
  LABEL $release
    MENU LABEL primary kernel
    LINUX /boot/linux-${release}
    FDTDIR /boot
    APPEND console=ttyS0,115200 cma=256M
EOF
cp -rpl rootfs/boot/. rescue/.
mv tmp/extlinux.conf rescue/
rm -rf tmp
