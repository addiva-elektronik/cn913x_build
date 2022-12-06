#!/bin/sh
cmd=./runme.sh
opt=
for arg; do
	case $arg in
	--shell)
		cmd=/bin/bash
		opt="-i -t --detach-keys="
	;;
	*)
		cmd="$cmd $arg"
	;;
	esac
done
if ! docker image inspect --format=" " cn913x_build 2>/dev/null; then
	docker build --build-arg user=$(whoami) \
		--build-arg userid=$(id -u) -t cn913x_build docker/
fi
exec docker run --rm -i -t \
	-v "$PWD":/cn913x_build_dir \
	-v $HOME/.gitconfig:/etc/gitconfig \
	$opt \
	cn913x_build \
	env BOARD_CONFIG=0 CP_NUM=3 $cmd
