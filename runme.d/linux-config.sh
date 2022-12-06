echo "Configuring the kernel with $ROOTDIR/configs/linux/cn913x_additions.config"
cd $ROOTDIR/build/linux
#make defconfig
./scripts/kconfig/merge_config.sh arch/arm64/configs/defconfig $ROOTDIR/configs/linux/cn913x_additions.config
