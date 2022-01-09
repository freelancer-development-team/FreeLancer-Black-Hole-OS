#! /bin/sh
# Copyright (C) 2021, FreeLancer Development Team
# All right's reserved...
#
# Tests the operating system

scriptpath="$(dirname $(realpath $0))"
. "$scriptpath/common.sh"

target=i386-pc

for var in "$@"; do
	if [ "$var" == "i386" ]; then
		target=i386-pc
	elif [ "$var" == "arm" ]; then
		target=arm
	else
		echo "Using default target $target"
	fi
done

which qemu-system-$target || fatal "QEMU for target $target is not in the PATH."

info "Testing QEMU for target $target"

qemu-system-$target -hdd hdd/hdd16m-$target -m 128 -smp cpu=2,cores=2,threads=2 -no-reboot -no-shutdown
onerror