#!/bin/sh
set -e

sudo apt-get update
sudo apt-get install -y build-essential wget git flex bison texinfo coreutils diffutils gcc gettext make perl sed binutils libgmp3-dev libmpc-dev libmpfr-dev libisl-dev

: ${ARCH:=i686}
: ${OS:=freebsd}
: ${OSVERSION:=10}
: ${GCC_VERSION:=13.2.0}
: ${BINUTILS_VERSION:=2.41}
: ${TARGET:=$ARCH-$OS$OSVERSION}
: ${PREFIX:=$PWD/cross-freebsd}
: ${PATH:=$PREFIX/bin:$PATH}
if [ $ARCH = "x86_64" ]; then
    : ${ARCH_ALIAS:=amd64}
else
    : ${ARCH_ALIAS:=i386}
fi
mkdir -p $PREFIX/lib
mkdir -p $PREFIX/usr/lib
mkdir -p $PREFIX/usr/include


mkdir base/
if [ $OSVERSION -lt 9 ]; then
  wget -r -nd -A "base.*" ftp://ftp-archive.freebsd.org/pub/FreeBSD-Archive/old-releases/$ARCH_ALIAS/$OSVERSION.0-RELEASE/base/
  cat base.?? | tar -xpzf - -C base/
else
  wget http://ftp-archive.freebsd.org/pub/FreeBSD-Archive/old-releases/$ARCH_ALIAS/$OSVERSION.0-RELEASE/base.txz
  tar -xpf base.txz -C base/
fi

cp -r base/usr/include $PREFIX/usr/
cp -r base/usr/lib $PREFIX/usr/
cp -r base/lib $PREFIX/ || true
cd $PREFIX/usr/lib
find . -xtype l | xargs ls -l | grep ' /lib/' | awk '{print "ln -sf ../.." $11 " " $9}' | /bin/sh
cd ../../../


wget https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.xz
tar -xf binutils-$BINUTILS_VERSION.tar.xz
mkdir build-binutils; cd build-binutils
../binutils-$BINUTILS_VERSION/configure --enable-libssp --enable-gold --enable-ld --target=$TARGET --prefix=$PREFIX --with-sysroot=$PREFIX --disable-multilib
make -j 3
make install
cd ../

wget https://gcc.gnu.org/pub/gcc/releases/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz
tar -xf gcc-$GCC_VERSION.tar.xz
cd gcc-$GCC_VERSION
./contrib/download_prerequisites
cd ../
mkdir build-gcc; cd build-gcc
../gcc-$GCC_VERSION/configure --without-headers --with-gnu-as --with-gnu-ld --enable-languages=c,c++ --disable-nls --enable-libssp --enable-gold --enable-ld --with-newlib --target=$TARGET --prefix=$PREFIX --disable-libgomp --with-sysroot=$PREFIX --disable-multilib --disable-libsanitizer
LD_LIBRARY_PATH=$PREFIX/lib make -j 2
make install
cd ../

tar -czf $TARGET.tar.gz -C $PREFIX .
echo "FreeBSD cross-compilation toolchain created successfully!"
