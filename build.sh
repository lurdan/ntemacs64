#!/bin/bash

EMACSVER=${1:-26.1}
TARGET=${2:-/c/emacs}
WORKDIR=${3:-~/tmp}

DEPLIBS="libffi-6.dll libgcc_s_seh-1.dll libgmp-10.dll libhogweed-4.dll libiconv-2.dll libidn2-0.dll libintl-8.dll libnettle-6.dll libp11-kit-0.dll libtasn1-6.dll libunistring-2.dll libwinpthread-1.dll"
DEPPKGS=$(echo mingw-w64-x86_64-{xpm-nox,libtiff,giflib,libpng,libjpeg-turbo,librsvg,libxml2,gnutls,lcms2,zlib,jansson})

_prepare () {
  pacman --noconfirm -Syu
  pacman --needed --noconfirm -S base-devel unzip $DEPPKGS $DEPPKGS_PDF
}

_fetch () {
  mkdir -p ${WORKDIR}/src
  cd ${WORKDIR}/src
  curl -O http://ftp.gnu.org/gnu/emacs/emacs-${EMACSVER}.tar.gz
  curl -O http://ftp.gnu.org/gnu/emacs/emacs-${EMACSVER}.tar.gz.sig

  curl -O https://gist.githubusercontent.com/rzl24ozi/ee4457df2f54c5f3ca0d02b56e371233/raw/16794e5883211049aed08c681f71240fa32cc28f/emacs-26.1-rc1-w32-ime.diff
  curl -O https://gist.githubusercontent.com/rzl24ozi/da3370acb767096ce11fe867c6d9da6a/raw/1e0c1e44c9042b182e499f94fd0b5ebfc9cd94a7/emacs-26.1-rc1-disable-w32-ime.diff
  curl -O https://raw.githubusercontent.com/mhatta/emacs-26-x86_64-win-ime/master/cmigemo-1.3-mingw64-20180629.zip
}

_extract () {
  cd ${WORKDIR}
  tar zxf ${WORKDIR}/src/emacs-${EMACSVER}.tar.gz -C $WORKDIR
  cd ${WORKDIR}/emacs-*
  for PATCH in $(ls -r ${WORKDIR}/src/*.diff)
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
  unzip src/cmigemo*.zip
  cp cmigemo-mingw64/bin/* ${TARGET}/bin
  cp -R cmigemo-mingw64/share/migemo ${TARGET}/share/
}

_prepare
_fetch
_extract
_build
_install
_cmigemo

