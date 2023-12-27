#!/bin/sh

sudo apt-get update
sudo apt-get install -y build-essential wget git flex bison texinfo coreutils diffutils gcc gettext make perl sed binutils libgmp3-dev libmpc-dev libmpfr-dev libisl-dev

export TARGET=i386-freebsd10
export PREFIX=/usr/cross-freebsd
export PATH=$PREFIX/bin:$PATH
mkdir -p $PREFIX{,/lib,/usr/lib,/usr/include}

wget http://ftp-archive.freebsd.org/pub/FreeBSD-Archive/old-releases/i386/10.0-RELEASE/base.txz
mkdir base/
tar -xf base.txz -C base/
cp -r base/usr/include $PREFIX/usr/
cp -r base/usr/lib $PREFIX/usr/
cp -r base/lib $PREFIX/
pushd $PREFIX/usr/lib
find . -xtype l | xargs ls -l | grep ' /lib/' | awk '{print "ln -sf /usr/cross-freebsd" $11 " " $9}' | /bin/sh
popd

wget https://ftp.gnu.org/gnu/binutils/binutils-2.41.tar.xz
tar -xf binutils-2.41.tar.xz
cd binutils-2.41
mkdir build; cd build
../configure --enable-libssp --enable-gold --enable-ld --target=$TARGET --prefix=$PREFIX --with-sysroot=$PREFIX --disable-multilib
make -j 3
make install
cd ../../

wget https://gcc.gnu.org/pub/gcc/releases/gcc-13.2.0/gcc-13.2.0.tar.xz
tar -xf gcc-13.2.0.tar.xz
cd gcc-13.2.0
./contrib/download_prerequisites
mkdir build; cd build
../configure --without-headers --with-gnu-as --with-gnu-ld --enable-languages=c,c++ --disable-nls --enable-libssp --enable-gold --enable-ld --target=$TARGET --prefix=$PREFIX --disable-libgomp --host=x86_64-pc-linux-gnu --with-sysroot=$PREFIX --disable-multilib --disable-libsanitizer
LD_LIBRARY_PATH=$PREFIX/lib make -j 2
make install
echo "FreeBSD 10 cross-compilation toolchain created successfully!"
