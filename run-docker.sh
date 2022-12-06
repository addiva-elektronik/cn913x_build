#!/bin/sh
cmd=./runme.sh
opt=
for arg; do
	case $arg in
	--shell|shell)
		cmd="$cmd shell"
		opt="-i -t --detach-keys="
		;;
	--edit)
		echo
		echo "Make any changes needed, then exit"
		echo
		id=$(docker run --rm -d cn913x_build sleep 3600)
		docker exec --user root -i -t $id bash
		echo -n "Commit changes to cn913x_build ?"
		read ans
		if [ "x$ans" == "xy" ]; then
		    docker commit $id cn913x_build
		fi
		docker kill $id >/dev/null
		exit
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
