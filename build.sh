#!/bin/bash

EMACSVER=${1:-26.1}
TARGET=${2:-/c/emacs}
WORKDIR=${3:-~/tmp}

DEPLIBS="libffi-6.dll libgcc_s_seh-1.dll libgmp-10.dll libhogweed-4.dll libiconv-2.dll libidn2-0.dll libintl-8.dll libnettle-6.dll libp11-kit-0.dll libtasn1-6.dll libunistring-2.dll libwinpthread-1.dll"
DEPPKGS=$(echo mingw-w64-x86_64-{xpm-nox,libtiff,giflib,libpng,libjpeg-turbo,librsvg,libxml2,gnutls,lcms2,zlib,jansson})

_prepare () {
  pacman --noconfirm -Syu
  pacman --needed --noconfirm -S base-devel $DEPPKGS $DEPPKGS_PDF
}

_extract () {
  tar zxf /c/emacs-${EMACSVER}.tar.gz -C $WORKDIR
  cd ${WORKDIR}/emacs-*
  for PATCH in /c/*.diff
  do
    patch -p0 < $PATCH
  done
}

_build () {
  #autoconf
  ./autogen.sh
  PKG_CONFIG_PATH=/mingw64/lib/pkgconfig/ CFLAGS='-O2 -march=x86-64 -mtune=generic -static -s -g0' \
    LDFLAGS='-s' ./configure --prefix=$TARGET \
                --host=x86_64-w64-mingw32 \
                --with-wide-int \
                --without-dbus \
                --without-compress-install \
                --with-json \
                --with-lcms2 \
                --with-modules && make bootstrap
}

_install () {
  make install-strip
  ( cd /mingw64/bin/; cp $DEPLIBS ${TARGET}/bin )
  cp $( pacman -Ql $DEPPKGS | awk '/bin\/.*\.dll$/{print $2}') ${TARGET}/bin
}

_cmigemo () {
  cd ${WORKDIR}
  unzip /c/cmigemo*.zip
  cp cmigemo-mingw64/bin/* ${TARGET}/bin
  cp -R cmigemo-mingw64/share/migemo ${TARGET}/share/
}

_prepare
_extract
_build
_install
_cmigemo

