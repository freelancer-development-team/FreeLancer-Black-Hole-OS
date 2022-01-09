#! /bin/sh
# Copyright (C) 2021, FreeLancer Development Team
# All right's reserved...
#
# Build binutils

scriptpath="$(dirname $(realpath $0))"

. "$scriptpath/common.sh"

headline "Building GNU-Binutils package. (binutils-$BINUTILS_VERSION)"
info "Checking for existence of global build variables."

isset TARGET
isset PREFIX
isset BINUTILS_SOURCE_DIR
isset BINUTILS_VERSION
isset TEMP_BUILDDIR
isset TEMP_BINUTILS
isset BINUTILS_BUILD_LOG
isset TARGET_BLACKHOLE

BINUTILS_TEMPBUILD_DIR="$ABSOLUTE_PATH/$TEMP_BUILDDIR/$TEMP_BINUTILS"

cd $BINUTILS_TEMPBUILD_DIR
onerror

#################### Print a header for the build log #########################

echo "================================================================================" >> $BINUTILS_BUILD_LOG 2>&1
echo "                      GNU BINUTILS $BINUTILS_VERSION BUILD LOG" >> $BINUTILS_BUILD_LOG 2>&1
echo >> $BINUTILS_BUILD_LOG 2>&1
echo "Current date: $(date +%T%t%d/%m/%Y%t%Z)" >> $BINUTILS_BUILD_LOG 2>&1
echo "Current user: $(whoami)" >> $BINUTILS_BUILD_LOG 2>&1
echo "Host name: $(hostname)" >> $BINUTILS_BUILD_LOG 2>&1
echo "================================================================================" >> $BINUTILS_BUILD_LOG 2>&1
echo >> $BINUTILS_BUILD_LOG 2>&1

###############################################################################

if [ $TARGET_BLACKHOLE == 1 ]; then
	info "Reconfiguring binutils/ld directory."
	pushd "$BINUTILS_SOURCE_DIR/ld"
	automake >> $BINUTILS_AUTORECONF_LOG 2>&1
	onerror
	popd
fi

info "Configuring GNU Binutils $BINUTILS_VERSION."
$BINUTILS_SOURCE_DIR/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot="$PREFIX" --disable-nls --disable-werror --enable-shared >> $BINUTILS_BUILD_LOG 2>&1
onerror

info "Building GNU Binutils $BINUTILS_VERSION"
make -j8 >> $BINUTILS_BUILD_LOG 2>&1
onerror

info "Installing GNU Binutils $BINUTILS_VERSION"
make -j8 install >> $BINUTILS_BUILD_LOG 2>&1
onerror

target_successful
cd ../..
onerror
