cd images
release=$(cat kernel_release)
freespace=512

# Make sure there is some free space
cp ubuntu-$release.ext4 tmp/ubuntu-core.ext4
e2fsck -f tmp/ubuntu-core.ext4
minsize=$(resize2fs -P tmp/ubuntu-core.ext4 | cut -d: -f2) # In 4K blocks
size=$(((minsize * 4 + 512 * 1024 + 1024 - 1 )/1024)) # in KB
size=$(((size + 1023) / 1024 * 1024)) # Round to nearest MB
resize2fs tmp/ubuntu-core.ext4 $((size*1024/4))

# Boot partition in KByte, must match u-boot config
root_start=64
boot_start=2048
boot_end=4096 # 0x400000 bytes
env_size=64
root_size=$((size-root_start-1))

mkdir -p tmp
rm -f tmp/ubuntu-core.img
truncate -s ${size}M tmp/ubuntu-core.img
sfdisk -q tmp/ubuntu-core.img << %PTBL%
label: gpt
unit: sectors
first-lba: 128

# Reserved partitions
start=$((boot_start*2)) size=$(((boot_end-env_size-boot_start)*2)) type=8DA63339-0007-60C0-C436-083AC8230908 name=Bootloader attrs=RequiredPartition
start=$(((boot_end-env_size)*2)) size=$((env_size*2)) type=8DA63339-0007-60C0-C436-083AC8230908 name=Environment attrs=RequiredPartition
# aarch64 root partition
start=${root_start}M name=Linux type=B921B045-1DF0-41C3-AF44-4C6F280D3FAE attrs=LegacyBIOSBootable
%PTBL%
ROOTPART=$(sfdisk --part-uuid tmp/ubuntu-core.img 3)
sfdisk -d tmp/ubuntu-core.img
rootsize=$(sfdisk -d tmp/ubuntu-core.img |grep Linux | cut -d= -f 3 | cut -d, -f1)
e2fsck -f tmp/ubuntu-core.ext4
resize2fs tmp/ubuntu-core.ext4 $((rootsize/2/4)) # 512 byte sectors in 4K blocks


mkdir -p extlinux/
cat > extlinux/extlinux.conf << EOF
  TIMEOUT 30
  DEFAULT linux
  MENU TITLE linux-cn913x boot options
  LABEL primary
    MENU LABEL primary kernel
    LINUX /boot/linux-${release}
    FDTDIR /boot
    APPEND console=ttyS0,115200 root=PARTUUID=${ROOTPART} rw rootwait cma=256M
EOF
e2mkdir -G 0 -O 0 tmp/ubuntu-core.ext4:boot/extlinux
e2cp -G 0 -O 0 extlinux/extlinux.conf tmp/ubuntu-core.ext4:boot/extlinux/


dd if=tmp/ubuntu-core.ext4 of=tmp/ubuntu-core.img bs=1M seek=$root_start conv=notrunc
rm tmp/ubuntu-core.ext4
dd if=boot-${DTB_UBOOT}-${UBOOT_ENVIRONMENT}.bin of=tmp/ubuntu-core.img bs=512 seek=4096 conv=notrunc
OUT=$ROOTDIR/images/sdcard-ubuntu-${DTB_KERNEL}-${release}-${UBOOT_ENVIRONMENT}.img
mv tmp/ubuntu-core.img $OUT

echo
echo "SDCARD image created at $OUT"
echo
