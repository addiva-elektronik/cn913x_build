echo "Manually configuring the kernel"
cd $ROOTDIR/build/linux
make menuconfig
make savedefconfig
mv defconfig defconfig_manual
./scripts/diffconfig defconfig_cn913x_additions defconfig_manual | while read opt val; do
	plus="$(echo "$opt" |cut -c-1)"
	opt="CONFIG_$(echo "$opt" |cut -c2-)"
	case "$plus" in
	"-")
		val="n"
		;;
	esac
	echo "${opt}=${val}"
done > defconfig.diff
cat defconfig.diff
echo "Enter tag to save  changes to defconfig (blank aborts)"
echo -n "Tag: "
read ans
if [ "x$ans" != "x" ]; then
    echo "" >> $ROOTDIR/configs/linux/cn913x_additions.config
    echo "# $ans" >> $ROOTDIR/configs/linux/cn913x_additions.config
    echo "" >> $ROOTDIR/configs/linux/cn913x_additions.config
    cat defconfig.diff  >> $ROOTDIR/configs/linux/cn913x_additions.config
fi
