cd images
mkdir -p tmp
truncate -s 520M tmp/ubuntu-core.img
sfdisk -q tmp/ubuntu-core.img << %PTBL%
label: gpt
unit: sectors
first-lba: 128

start=440 size=6MB type=00000000-0000-0000-0000-000000000000 name=Bootloader attrs=RequiredPartition
start=16384 size=1MB type=00000000-0000-0000-0000-000000000000 name=Environment attrs=RequiredPartition
start=64MB name=Linux bootable
%PTBL%
ROOTPART=$(sfdisk --part-uuid tmp/ubuntu-core.img 3)
sfdisk -d tmp/ubuntu-core.img

cp ubuntu-${DTB_KERNEL}-${KERNEL_RELEASE}.ext4 tmp/ubuntu-core.ext4
mkdir -p tmp/extlinux/
cat > tmp/extlinux/extlinux.conf << EOF
  TIMEOUT 30
  DEFAULT linux
  MENU TITLE linux-cn913x boot options
  LABEL primary
    MENU LABEL primary kernel
    LINUX /boot/Image
    FDTDIR /boot
    APPEND console=ttyS0,115200 root=PARTUUID=${ROOTPART} rw rootwait cma=256M
EOF
e2mkdir -G 0 -O 0 tmp/ubuntu-core.ext4:extlinux
e2cp -G 0 -O 0 tmp/extlinux/extlinux.conf tmp/ubuntu-core.ext4:extlinux/

dd if=tmp/ubuntu-core.ext4 of=tmp/ubuntu-core.img bs=1M seek=64 conv=notrunc
rm tmp/ubuntu-core.ext4
dd if=boot-${DTB_UBOOT}-${UBOOT_ENVIRONMENT}.bin of=tmp/ubuntu-core.img bs=512 seek=4096 conv=notrunc
OUT=$ROOTDIR/images/ubuntu-${DTB_KERNEL}-${KERNEL_RELEASE}-${UBOOT_ENVIRONMENT}.img
mv tmp/ubuntu-core.img $OUT

echo
echo "SDCARD image created at $OUT"
echo
