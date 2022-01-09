#! /bin/sh
# Copyright (C) 2021, FreeLancer Development Team
# All right's reserved...
#
# Build GCC

scriptpath="$(dirname $(realpath $0))"
. "$scriptpath/common.sh"

headline "Building GNU-GCC package. (GCC-$GCC_VERSION)"

GCC_PKGVERSION=0.8.6

info "Checking for existence of global build variables."
isset TARGET
isset PREFIX
isset GCC_SOURCE_DIR
isset GCC_VERSION
isset TEMP_BUILDDIR
isset TEMP_GCC
isset GCC_BUILD_LOG

GCC_PREFIX="$(echo $PREFIX | sed -re 's/\/([a-zA-Z])\//\1:\//' )"
info "GCC Win32 compatible prefix: $GCC_PREFIX"

GCC_BUILDDIR_TEMP="$ABSOLUTE_PATH/$TEMP_BUILDDIR/$TEMP_GCC"

cd "$GCC_BUILDDIR_TEMP"

#################### Print a header for the build log #########################

echo "================================================================================" >> $GCC_BUILD_LOG 2>&1
echo "                      GNU GCC $GCC_VERSION BUILD LOG" >> $GCC_BUILD_LOG 2>&1
echo >> $GCC_BUILD_LOG 2>&1
echo "Current date: $(date +%T%t%d/%m/%Y%t%Z)" >> $GCC_BUILD_LOG 2>&1
echo "Current user: $(whoami)" >> $GCC_BUILD_LOG 2>&1
echo "Host name: $(hostname)" >> $GCC_BUILD_LOG 2>&1
echo "================================================================================" >> $GCC_BUILD_LOG 2>&1
echo >> $GCC_BUILD_LOG 2>&1

###############################################################################

info "Autoconf-Automake invokation for GNU GCC"
pushd "$GCC_SOURCE_DIR/libstdc++-v3"
autoconf >> $GCC_AUTORECONF_LOG 2>&1
onerror
popd

cd "$GCC_BUILDDIR_TEMP"

LIBRARIES_OPTION=''

if [ $USE_LIBRARIES == 1 ]; then

info "Checking for existence of libraries"

# Check for existence of libraries
isset MPC_VERSION
isset MPFR_VERSION
isset GMP_VERSION
isset ISL_VERSION
isset PACKAGES_DIR
isset GNU_ID

MPC_SOURCEDIR="$PACKAGES_DIR/$GNU_ID/mpc-$MPC_VERSION"
MPFR_SOURCEDIR="$PACKAGES_DIR/$GNU_ID/mpfr-$MPFR_VERSION"
GMP_SOURCEDIR="$PACKAGES_DIR/$GNU_ID/gmp-$GMP_VERSION"
ISL_SOURCEDIR="$PACKAGES_DIR/$GNU_ID/isl-$ISL_VERSION"

checkpath $MPC_SOURCEDIR
checkpath $MPFR_SOURCEDIR
checkpath $GMP_SOURCEDIR
checkpath $ISL_SOURCEDIR

# If libraries are installed we don't need to build them.
MPC_PREFIX="$LIBRARIES_DIR/mpc-$MPC_VERSION"
MPFR_PREFIX="$LIBRARIES_DIR/mpfr-$MPFR_VERSION"
GMP_PREFIX="$LIBRARIES_DIR/gmp-$GMP_VERSION"
ISL_PREFIX="$LIBRARIES_DIR/isl-$ISL_VERSION"

LIBRARIES_OPTION="--with-gmp="$GMP_PREFIX" --with-mpc="$MPC_PREFIX" --with-mpfr="$MPFR_PREFIX" --with-isl="$ISL_PREFIX""

info "Building libraries for GNU GCC $GCC_VERSION"
if ! isdir "$GMP_PREFIX"; 
then
	# Build GMP library
	mkdir libgmp
	cd libgmp
	
	info "Building GMP Library"
	
	$GMP_SOURCEDIR/configure --prefix="$GMP_PREFIX" >> $GCC_BUILD_LOG 2>&1
	onerror
	make -j7 >> $GCC_BUILD_LOG 2>&1
	onerror
	make -j7 check >> $GCC_BUILD_LOG 2>&1
	onerror
	make -j7 install >> $GCC_BUILD_LOG 2>&1
	onerror
		 
	# Get back
	getback
else
	warning "No need to build GMP-$GMP_VERSION library."
fi
if ! isdir "$MPFR_PREFIX"; 
then
	# Build MPFR library
	mkdir libmpfr
	cd libmpfr
	
	info "Building MPFR Library"
	
	$MPFR_SOURCEDIR/configure --prefix="$MPFR_PREFIX" --with-gmp="$GMP_PREFIX" --disable-shared >> $GCC_BUILD_LOG 2>&1
	onerror
	make -j7 >> $GCC_BUILD_LOG 2>&1
	onerror
	make -j7 check >> $GCC_BUILD_LOG 2>&1
	onerror
	make -j7 install >> $GCC_BUILD_LOG 2>&1
	onerror
	
	# Return
	getback
else
	warning "No need to build MPFR-$MPFR_VERSION library."
fi
if ! isdir "$MPC_PREFIX"; 
then 
	# Build MPC library
	mkdir libmpc
	cd libmpc
	
	info "Building MPC Library"
	
	$MPC_SOURCEDIR/configure --prefix="$MPC_PREFIX" --with-gmp="$GMP_PREFIX" --with-mpfr="$MPFR_PREFIX" --disable-shared >> $GCC_BUILD_LOG 2>&1
	onerror
	make -j7 >> $GCC_BUILD_LOG 2>&1
	onerror
	make -j7 check >> $GCC_BUILD_LOG 2>&1
	onerror
	make -j7 install >> $GCC_BUILD_LOG 2>&1
	onerror
	
	# Return to previous directory
	getback
else
	warning "No need to build MPC-$MPC_VERSION library."
fi
if ! isdir "$ISL_PREFIX"; 
then
	# Build ISL library
	mkdir libisl
	cd libisl
	
	info "Building ISL Library"
	
	$ISL_SOURCEDIR/configure --prefix="$ISL_PREFIX" --with-gmp-prefix="$GMP_PREFIX" --disable-shared >> $GCC_BUILD_LOG 2>&1
	onerror
	make -j7 >> $GCC_BUILD_LOG 2>&1
	onerror
	make -j7 install >> $GCC_BUILD_LOG 2>&1
	onerror
	
	getback
else
	warning "No need to build ISL-$ISL_VERSION library."
fi

else
	warning "Using system default provided libraries... Make sure you have them."
fi

info "Checking for binutils installation for target $TARGET is in the path"
# The $PREFIX/bin dir _must_ be in the PATH. We did that above.
which -- $TARGET-as || error "$TARGET-as is not in the PATH" 

info "Passing the following options to configure script (regarding libraries): $LIBRARIES_OPTION"

info "Configuring GNU GCC $GCC_VERSION for building."
../../packages/gnu/gcc-$GCC_VERSION/configure --target=$TARGET --prefix="$GCC_PREFIX" \
	$LIBRARIES_OPTION \
    --disable-nls \
    --enable-languages=c,c++ \
    --disable-werror  \
	--enable-shared \
    --with-gcc \
    --with-gnu-as \
    --with-gnu-ld \
    --disable-win32-registry \
	--with-sysroot="$PREFIX" \
	--with-pkgversion="$GCC_PKGVERSION, built for BlackHoleOS project." >> $GCC_BUILD_LOG 2>&1
onerror

if [ $BUILD_LIBGCC_ONLY == 0 ]; then

info "Building GNU GCC $GCC_VERSION"
make -j8 all-gcc >> $GCC_BUILD_LOG 2>&1
onerror
info "Installing GNU GCC $GCC_VERSION"
make -j8 install-gcc >> $GCC_BUILD_LOG 2>&1
onerror

else
warning "Skipping GNU GCC main program build. Direct to GCC Libgcc build."
fi

info "Building GNU libgcc for GCC $GCC_VERSION"
make -j8 all-target-libgcc >> $GCC_BUILD_LOG 2>&1
onerror
info "Installing libgcc for target $TARGET"
make -j8 install-target-libgcc >> $GCC_BUILD_LOG 2>&1
onerror

target_successful
cd ../..
