#! /bin/sh
# Copyright (C) 2021, FreeLancer Development Team
# All right's reserved...
#
# Build toolchain

scriptpath="$(dirname $(realpath $0))"
. "$scriptpath/common.sh"

# Variables
BUILD_BINUTILS=0
BUILD_GCC=0

TARGET=i386-blackhole
BINUTILS_VERSION=2.36.1
GCC_VERSION=10.2.0
GMP_VERSION=6.2.1
ISL_VERSION=0.23
MPFR_VERSION=4.1.0
MPC_VERSION=1.2.1

TARGET_BLACKHOLE=1

REQUIRED_AUTOCONF="autoconf (GNU Autoconf) 2.69"
REQUIRED_AUTORECONF=0

TEMP_BUILDDIR="build"
TEMP_BINUTILS="binutils"
TEMP_GCC="gcc"

STEP_CLEAN=0
STEP_DISTCLEAN=0
STEP_PATCH=0
USE_LIBRARIES=1
BUILD_LIBGCC_ONLY=0

# Log files
BINUTILS_CLEAN_LOG="$ABSOLUTE_PATH/binutils-clean.log"
BINUTILS_BUILD_LOG="$ABSOLUTE_PATH/binutils-build.log"
GCC_CLEAN_LOG="$ABSOLUTE_PATH/gcc-clean.log"
GCC_BUILD_LOG="$ABSOLUTE_PATH/gcc-build.log"
GCC_PATCH_LOG="$ABSOLUTE_PATH/gcc-patch.log"
BINUTILS_PATCH_LOG="$ABSOLUTE_PATH/binutils-patch.log"
GCC_AUTORECONF_LOG="$ABSOLUTE_PATH/gcc-reconfiguration.log"
BINUTILS_AUTORECONF_LOG="$ABSOLUTE_PATH/binutils-reconfiguration.log"

# Packages
export PACKAGES_DIR="$ABSOLUTE_PATH/packages"
export LIBRARIES_DIR="$ABSOLUTE_PATH/lib"
export GNU_ID="gnu"

# Make variables
export CFLAGS='-O3 -pipe'
export CXXFLAGS='-O3 -pipe'

# Parse parameters
for var in "$@"; do
    echo "$var" >> argument 2>&1
    order="$(cut -f 1 -d '=' argument)"
    arg="$(cut -f 2 -d '=' argument)"
    rm -f argument
    
    if [ $var == "--help" ]; then
        headline "Copyright (C) 2021, FreeLancer Development Team."
        headline "All right's reserved..."
        echo
        echo "usage: build-toolchain.sh [options]"
        echo
        echo "where possible options may include:"
        echo "  --build-binutils                Builds GNU Binutils"
        echo "  --build-gcc                     Builds GNU GCC"
        echo "  --libgcc-only                   Builds GNU GCC companion library (libgcc) only"
        echo "  --patch                         Patch GNU GCC & GNU Binutils. (target is"
        echo "                                  selected automatically as the build target)"
        echo "  --target=[target]               Sets the target to the next argument passed."
        echo "  --binutils-version=[version]    Sets the desired binutils package version."
        echo "  --gcc-version=[version]         Sets the desired gcc package version."
        echo "  --mpc-version=[version]         Sets the MPC library version"
        echo "  --mpfr--version=[version]       Sets the MPFR library version"
        echo "  --gmp-version=[version]         Sets the GMP library version"
        echo "  --isl-version=[version]         Sets the ISL library version"
        echo "  --no-libraries                  Use the system libraries instead of provided"
        echo "  --clean                         Executes make clean once finished building"
        echo "  --distclean=[version]           Cleans the installation for version. Target is set using target."
        echo
        echo "possible targets may include:"
        echo "  i386-blackhole                  Intel i386 ELF BlackHoleOS target (default)"
        echo "  x86_64-blackhole                AMD64 BlackHoleOS target"
        echo "  i386-elf                        Intel i386 ELF 'naked' target."
        echo "  i486-elf                        Intel i486 ELF 'naked' target."
        echo "  i686-elf                        Intel Pentium Pro ELF 'naked' target."
        echo "  x86_64-elf                      AMD64 'naked' target."
        echo "  arm-elf                         ARM ELF 'naked' target."
        exit 0
    elif [ $var == "--build-binutils" ]; then
        BUILD_BINUTILS=1
    elif [ $var == "--build-gcc" ]; then
        BUILD_GCC=1
    elif [ $var == "--patch" ]; then
        STEP_PATCH=1
    elif [ $order == "--target" ]; then
        TARGET=$arg
        info "Set new target: $TARGET"
    elif [ $order == "--binutils-version" ]; then
        BINUTILS_VERSION=$arg
    elif [ $order == "--gcc-version" ]; then
        GCC_VERSION=$arg
    elif [ $order == "--mpc-version" ]; then
        MPC_VERSION=$arg
    elif [ $order == "--mpfr-version" ]; then
        MPFR_VERSION=$arg
    elif [ $order == "--gmp-version" ]; then
        GMP_VERSION=$arg
    elif [ $order == "--isl-version" ]; then
        ISL_VERSION=$arg
    elif [ $var == "--no-libraries" ]; then
        USE_LIBRARIES=0
    elif [ $var == "--libgcc-only" ]; then
        BUILD_LIBGCC_ONLY=1
    elif [ $var == "--clean" ]; then
        STEP_CLEAN=1
    elif [ $order == "--distclean" ]; then
        GCC_VERSION=$arg
        STEP_DISTCLEAN=1
    else
        error "unknown parameter: $var"
        exit 0
    fi
done

echo "$TARGET" >> triplet 2>&1
    machine="$(cut -f 1 -d '-' triplet)"
    system="$(cut -f 2 -d '-' triplet)"
    rm -f triplet
if [ $system == "blackhole" ]; then
    TARGET_BLACKHOLE=1
    info "Targeting native BlackHoleOS"
else
    TARGET_BLACKHOLE=0
    info "Targeting external or bare target"
fi
    
# Build prefix from target...
INSTALL_DIRNAME=gnu-gcc-$TARGET-$GCC_VERSION
info "Installation directory will be named: $INSTALL_DIRNAME"

BINDIR_PATH="$ABSOLUTE_PATH/bin"
PREFIX="$BINDIR_PATH/$INSTALL_DIRNAME"

info "Absolute path for installer: $PREFIX"

# Get the source directory for these packages.
info "Using GNU Binutils $BINUTILS_VERSION"
info "Using GNU GCC $GCC_VERSION"

BINUTILS_SOURCE_DIR="$ABSOLUTE_PATH/packages/gnu/binutils-$BINUTILS_VERSION"
GCC_SOURCE_DIR="$ABSOLUTE_PATH/packages/gnu/gcc-$GCC_VERSION"

if [ $BUILD_BINUTILS == 1 ]; then
    checkpath $BINUTILS_SOURCE_DIR
fi
if [ $BUILD_GCC == 1 ]; then
    checkpath $GCC_SOURCE_DIR
fi

# Check for the existence of required tools
headline "Checking for availability of tools."
rm -f "./tools-log.txt"

checktool "gcc"
checktool "as"
checktool "ld"
checktool "make"
checktool "autoconf"
checktool "automake"
checktool "aclocal"
checktool "autoheader"
checktool "libtool"
checktool "patch"
checktool "autoreconf"

# Check version of autoconf
headline "Checking GNU Autoconf version"
info "Required autoconf version: $REQUIRED_AUTOCONF"
autoconf --version | grep -q "$REQUIRED_AUTOCONF"
if [[ $? != 0 ]]; then
    info "    -> wrong autoconf version (reconfiguration required if patching):"
    echo "       $(autoconf --version | sed -n 1p)"
    REQUIRED_AUTORECONF=1
fi

# Global variables.
export PATH="$PREFIX/bin:$PATH"

# Install the system headers
headline "Installing system headers"
mkdir -p "$PREFIX"
onerror
mkdir -p "$PREFIX/system/include"
onerror
mkdir -p "$PREFIX/system/lib"
onerror

info "Copying C library headers"
checkpath libc/sources/include
cp -RT libc/sources/include "$PREFIX/system/include"
onerror

info "Terminated installation of system root"

# Apply patches
if [ $STEP_PATCH == 1 ]; then

    GCC_PATCH="$ABSOLUTE_PATH/patches/toolchain/gcc-$GCC_VERSION-blackhole.patch"
    BINUTILS_PATCH="$ABSOLUTE_PATH/patches/toolchain/binutils-$BINUTILS_VERSION-blackhole.patch"
    
    headline "Patching toolchain:"
    echo "GCC patch: $GCC_PATCH"
    echo "Binutils patch: $BINUTILS_PATCH"
    
    headline "Patching binutils"
    patch -d $BINUTILS_SOURCE_DIR -p 1 < $BINUTILS_PATCH        >> $BINUTILS_PATCH_LOG 2>&1
    
    info "Automake invokation for GNU Binutils"
    pushd "$BINUTILS_SOURCE_DIR/ld"
    automake >> $BINUTILS_AUTORECONF_LOG 2>&1
    onerror
    popd

    headline "Patching GCC" 
    patch -d $GCC_SOURCE_DIR -p 1 < $GCC_PATCH              >> $GCC_PATCH_LOG 2>&1
    
    echo "Updating autoconf in libstdc++-v3"
    pushd "$GCC_SOURCE_DIR/libstdc++-v3"   
    autoconf >> $GCC_AUTORECONF_LOG 2>&1
    onerror
    popd
        
else
    warning "Skipping patching process for GNU GCC & Binutils"
fi

# Preparing to build binutils
mkdir -p $TEMP_BUILDDIR
mkdir $TEMP_BUILDDIR/$TEMP_BINUTILS
mkdir $TEMP_BUILDDIR/$TEMP_GCC

# Build GNU Binutils if commanded.
if [ $BUILD_BINUTILS == 1 ]; then
    if [ -f build-binutils.sh ]; then
        # Remove the logs!!
        rm -f $BINUTILS_BUILD_LOG
        . "$scriptpath/build-binutils.sh"
    else
        error "Unable to find GNU Binutils build script??? Repository must be broken. Check the integrity of the obtained files."
        exit 1
    fi
else
    warning "Skipping build of GNU-Binutils"
fi

# Clean up BINUTILS
if [ $STEP_CLEAN == 1 ]; then
    headline "Cleaning GNU Binutils $BINUTILS_VERSION build."
    
    cd "$TEMP_BUILDDIR/$TEMP_BINUTILS"
    
    rm -f $BINUTILS_CLEAN_LOG
    make -j8 clean >> $BINUTILS_CLEAN_LOG 2>&1
    make -j8 distclean >> $BINUTILS_CLEAN_LOG 2>&1
    
    cd ../..
else
    info "No cleaning is performed for GNU-Binutils build."
fi

# Build GNU GCC if commanded
if [ $BUILD_GCC == 1 ]; then
    if [ -f build-gcc.sh ]; then
        # Remove the logs!!
        rm -f $GCC_BUILD_LOG
        . "$scriptpath/build-gcc.sh"
    else
        error "Unable to find GNU GCC build script??? Repository must be broken. Check the integrity of the obtained files."
        exit 1
    fi
else
    warning "Skipping build of GNU-GCC"
fi

# Clean up GCC
if [ $STEP_CLEAN == 1 ]; then
    headline "Cleaning GNU GCC $GCC_VERSION build."
    
    cd $TEMP_BUILDDIR/$TEMP_GCC
    
    rm -f $GCC_CLEAN_LOG
    make -j8 clean >> $GCC_CLEAN_LOG 2>&1
    make -j8 distclean >> $GCC_CLEAN_LOG 2>&1
    
    cd ../..
else
    info "No cleaning is performed for GNU-Binutils build."
fi

# Finish
info "Performing finalization of build script."

# Clean up installation if required
if [ $STEP_DISTCLEAN == 1 ]; then
    headline "Cleaning GNU GCC installation for target $TARGET and version $GCC_VERSION."
    cd bin
    
    DIR_TO_ERASE=gnu-gcc-$TARGET-$GCC_VERSION
    rm -rf $DIR_TO_ERASE
    
    cd ..
else
    info "No cleaning is performed for GNU-Binutils build."
fi

# GENERAL CLEANING!!
if [ $STEP_CLEAN == 1 ]; then
    headline "Cleaning temporary directories."
    rm -rf $TEMP_BUILDDIR
else
    info "No final cleanup is performed."
fi

# We are done
target_successful
exit 0
