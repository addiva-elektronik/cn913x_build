cd images
release=$(cat kernel_release)

mkdir -p tmp
truncate -s 520M tmp/ubuntu-core.img
sfdisk -q tmp/ubuntu-core.img << %PTBL%
label: gpt
unit: sectors
first-lba: 128

# Reserved partitions
start=440 size=6MB type=8DA63339-0007-60C0-C436-083AC8230908 name=Bootloader attrs=RequiredPartition
start=16384 size=1MB type=8DA63339-0007-60C0-C436-083AC8230908 name=Environment attrs=RequiredPartition
# aarch64 root partition
start=64MB name=Linux type=B921B045-1DF0-41C3-AF44-4C6F280D3FAE bootable
%PTBL%
ROOTPART=$(sfdisk --part-uuid tmp/ubuntu-core.img 3)
sfdisk -d tmp/ubuntu-core.img

cp ubuntu-$release.ext4 tmp/ubuntu-core.ext4
mkdir -p tmp/extlinux/
cat > tmp/extlinux/extlinux.conf << EOF
  TIMEOUT 30
  DEFAULT linux
  MENU TITLE linux-cn913x boot options
  LABEL primary
    MENU LABEL primary kernel
    LINUX /boot/linux-${release}
    FDTDIR /boot
    APPEND console=ttyS0,115200 root=PARTUUID=${ROOTPART} rw rootwait cma=256M
EOF
e2mkdir -G 0 -O 0 tmp/ubuntu-core.ext4:extlinux
e2cp -G 0 -O 0 tmp/extlinux/extlinux.conf tmp/ubuntu-core.ext4:extlinux/

dd if=tmp/ubuntu-core.ext4 of=tmp/ubuntu-core.img bs=1M seek=64 conv=notrunc
rm tmp/ubuntu-core.ext4
dd if=boot-${DTB_UBOOT}-${UBOOT_ENVIRONMENT}.bin of=tmp/ubuntu-core.img bs=512 seek=4096 conv=notrunc
OUT=$ROOTDIR/images/ubuntu-${DTB_KERNEL}-${release}-${UBOOT_ENVIRONMENT}.img
mv tmp/ubuntu-core.img $OUT

echo
echo "SDCARD image created at $OUT"
echo
