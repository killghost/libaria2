#! /bin/bash

if [ "$1"x = "x86"x ]; then 
    export ARCH=i686
elif [ "$1"x = "x64"x ]; then
    export ARCH=x86_64
else
    export ARCH=i686
fi

# 改成 x86_64-w64-mingw32 来编译64位版本
# 改成 i686-w64-mingw32 来编译32位版本
export HOST=$ARCH-w64-mingw32
export PREFIX=/usr/local/$HOST

# It would be better to use nearest ubuntu archive mirror for faster
# downloads.
# RUN sed -ie 's/archive\.ubuntu/jp.archive.ubuntu/g' /etc/apt/sources.list
# 安装编译环境
apt-get update && \
apt-get install -y make binutils autoconf automake autotools-dev libtool pkg-config git curl dpkg-dev gcc-mingw-w64 autopoint libcppunit-dev libxml2-dev libgcrypt11-dev lzip

# 下载依赖库
if [ ! -f "gmp-6.1.2.tar.lz" ]; then 
	curl -L -O https://gmplib.org/download/gmp/gmp-6.1.2.tar.lz 
fi

if [ ! -f "expat-2.2.8.tar.gz" ]; then 
	curl -L -O https://sourceforge.net/projects/expat/files/expat/2.2.8/expat-2.2.8.tar.gz
fi

if [ ! -f "sqlite-autoconf-3290000.tar.gz" ]; then 
	curl -L -O https://www.sqlite.org/2019/sqlite-autoconf-3290000.tar.gz
fi

if [ ! -f "zlib-1.2.11.tar.gz" ]; then 
	curl -L -O http://prdownloads.sourceforge.net/libpng/zlib-1.2.11.tar.gz
fi

if [ ! -f "c-ares-1.14.0.tar.gz" ]; then 
	curl -L -O https://c-ares.haxx.se/download/c-ares-1.14.0.tar.gz
fi

if [ ! -f "libssh2-1.9.0-20190922.tar.gz" ]; then 
	curl -L -O https://www.libssh2.org/snapshots/libssh2-1.9.0-20190922.tar.gz
fi

if [ ! -f "aria2-1.34.0.tar.xz" ]; then 
	curl -L -O https://github.com/aria2/aria2/releases/download/release-1.34.0/aria2-1.34.0.tar.xz
fi

# 动态编译 gmp
tar xf gmp-6.1.2.tar.lz && \
cd gmp-6.1.2 && \
./configure --enable-shared --disable-static --prefix=$PREFIX --host=$HOST --disable-cxx --enable-fat CFLAGS="-mtune=generic -O2 -g0" && \
make -j 16 install

# 动态编译 expat
cd ..
tar xf expat-2.2.8.tar.gz && \
cd expat-2.2.8 && \
./configure --enable-shared --disable-static --prefix=$PREFIX --host=$HOST --build=`dpkg-architecture -qDEB_BUILD_GNU_TYPE` && \
make -j 16 install

# 动态编译 sqlite3
cd ..
tar xf sqlite-autoconf-3290000.tar.gz && cd sqlite-autoconf-3290000 && \
./configure --enable-shared --disable-static --prefix=$PREFIX --host=$HOST --build=`dpkg-architecture -qDEB_BUILD_GNU_TYPE` && \
make -j 16 install

# 动态编译 zlib
cd ..
tar xf zlib-1.2.11.tar.gz && \
cd zlib-1.2.11
export BINARY_PATH=$PREFIX/bin
export INCLUDE_PATH=$PREFIX/include
export LIBRARY_PATH=$PREFIX/lib
make -j 16 install -f win32/Makefile.gcc PREFIX=$HOST- SHARED_MODE=1

# 动态编译 c-ares
cd ..
tar xf c-ares-1.14.0.tar.gz && \
cd c-ares-1.14.0 && \
./configure --enable-shared --disable-static --without-random --prefix=$PREFIX --host=$HOST --build=`dpkg-architecture -qDEB_BUILD_GNU_TYPE` LIBS="-lws2_32" && \
make -j 16 install

# 动态编译 libssh2
cd ..
tar xf libssh2-1.9.0-20190922.tar.gz && \
cd libssh2-1.9.0-20190922 && \
./configure --enable-shared --disable-static --prefix=$PREFIX --host=$HOST --build=`dpkg-architecture -qDEB_BUILD_GNU_TYPE` --without-openssl --with-wincng LIBS="-lws2_32" && \
make -j 16 install

# 编译aria2
cd ..
tar xf aria2-1.34.0.tar.xz && \
cd aria2-1.34.0 && \
autoreconf -i && \
./configure \
    --host=$HOST \
    --prefix=$PREFIX \
    --without-included-gettext \
    --disable-nls \
    --with-libcares \
    --without-gnutls \
    --with-openssl \
    --with-sqlite3 \
    --without-libxml2 \
    --with-libexpat \
    --with-libz \
    --with-libgmp \
    --with-libssh2 \
    --without-libgcrypt \
    --without-libnettle \
    --with-cppunit-prefix=$PREFIX \
    --enable-libaria2 \
    ARIA2_STATIC=no \
    CPPFLAGS="-I$PREFIX/include" \
    LDFLAGS="-L$PREFIX/lib" \
    PKG_CONFIG="/usr/bin/pkg-config" \
    PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" && \
make -j16 install

$HOST-strip $PREFIX/bin/libaria2-0.dll
$HOST-strip $PREFIX/bin/aria2c.exe