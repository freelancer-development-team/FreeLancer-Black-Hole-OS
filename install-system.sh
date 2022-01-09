#! /bin/sh
# Copyright (C) 2021, FreeLancer Development Team
# All right's reserved...
#
# Installs the Operating System files into the dist directory.

scriptpath="$(dirname $(realpath $0))"
. "$scriptpath/common.sh"

# Variables
TARGET=i386

DIST_DIR="$ABSOLUTE_PATH/dist"
SYSTEM_DIR="BlackHoleOS"
LIBRARIES_X32_DIR="System"
LIBRARIES_X64_DIR="System64"
INFO_DIR="Info"
FONTS_DIR="Fonts"

# Packages
KLIBC_DISTDIR="libc/dist/Release-$TARGET-Kernel"
HAL_DISTDIR="hal/dist/Release-$TARGET"
KERNEL_DISTDIR="kernel/dist/Release-$TARGET"

# Go, go, go!
headline "Installing Operating System files into 'dist' directory."

for var in "$@"; do
    echo "$var" >> argument 2>&1
    order="$(cut -f 1 -d '=' argument)"
    arg="$(cut -f 2 -d '=' argument)"
    rm -f argument
	
	if [ $order == "--target" ]; then
        TARGET=$arg	
	else
		error "unknown parameter: $var"
        exit 1
    fi
done

info "Creating subdirectories"
mkdir -p $DIST_DIR
cd $DIST_DIR
mkdir -p $SYSTEM_DIR
cd $SYSTEM_DIR
mkdir -p $LIBRARIES_X32_DIR
mkdir -p $LIBRARIES_X64_DIR
mkdir -p $INFO_DIR
mkdir -p $FONTS_DIR
getback
getback

info "Checking for release versions of programs for target $TARGET"
checkpath $KLIBC_DISTDIR
checkpath $KERNEL_DISTDIR

info "Copying into dist directory"
cp $KLIBC_DISTDIR/crtdll.dll $DIST_DIR/$SYSTEM_DIR
cp $HAL_DISTDIR/hal.dll $DIST_DIR/$SYSTEM_DIR
cp $KERNEL_DISTDIR/bhoskrnl.exe $DIST_DIR/$SYSTEM_DIR
