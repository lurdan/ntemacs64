#!/bin/bash
set -e

EMACSVER=${1:-27.2}
TARGET=${2:-/c/emacs}
WORKDIR=${3:-~/tmp}

DEPLIBS="libtiff libgdk_pixbuf libglib libgobject libffi libgmp libhogweed libiconv libidn2 libintl libnettle libp11-kit libtasn1 libunistring libwinpthread"
DEPPKGS=$(echo mingw-w64-x86_64-{toolchain,xpm-nox,libtiff,giflib,libpng,libjpeg-turbo,librsvg,libxml2,gnutls,lcms2,zlib,jansson})
DEPPKGS_PDF=$(echo mingw-w64-x86_64-{poppler,imagemagick})

_prepare () {
  pacman --needed --noconfirm -S base-devel unzip $DEPPKGS $DEPPKGS_PDF
}

_fetch () {
  mkdir -p ${WORKDIR}/src
  cd ${WORKDIR}/src
  curl -O http://ftp.gnu.org/gnu/emacs/emacs-${EMACSVER}.tar.gz
  curl -O http://ftp.gnu.org/gnu/emacs/emacs-${EMACSVER}.tar.gz.sig

  curl -O https://raw.githubusercontent.com/mhatta/emacs-27-x86_64-win-ime/master/cmigemo-1.3-mingw64-20180629.zip
  curl -fsSL -o gnutls.zip 'https://gitlab.com/gnutls/gnutls/-/jobs/491918191/artifacts/download?file_type=archive'
}

_extract () {
  cd ${WORKDIR}
  tar zxf ${WORKDIR}/src/emacs-${EMACSVER}.tar.gz --strip=1 -C $WORKDIR
}

_build () {
  #autoconf
  ./autogen.sh
  PKG_CONFIG_PATH=/mingw64/lib/pkgconfig/ CFLAGS='-O2 -march=x86-64 -mtune=generic -static -s -g0' \
    LDFLAGS='-s' ./configure --prefix=$TARGET \
                --host=x86_64-w64-mingw32 \
                --with-wide-int \
                --with-gnutls \
                --with-xml2 \
                --without-pop \
                --without-dbus \
                --without-compress-install \
                --with-lcms2 \
                --with-modules && make bootstrap
}

_install () {
  make install-strip
  ( cd /mingw64/bin/; ls *.dll; for LIB in $DEPLIBS; do cp ${LIB}-*.dll ${TARGET}/bin; done; cp libgcc_s_*.dll ${TARGET}/bin )
  cp $( pacman -Ql $DEPPKGS | awk '/bin\/.*\.dll$/{print $2}') ${TARGET}/bin
}

_cmigemo () {
  cd ${WORKDIR}
  unzip src/cmigemo*.zip
  cp cmigemo-mingw64/bin/* ${TARGET}/bin
  cp -R cmigemo-mingw64/share/migemo ${TARGET}/share/
}

_pdftools () {
  cd ${WORKDIR}
  git clone https://github.com/politza/pdf-tools
  cd pdf-tools
  PATH=$PATH:${TARGET}/bin make server/epdfinfo
  cp server/epdfinfo.exe ${TARGET}/bin
}

_dlls () {
  cd ${WORKDIR}
  unzip src/gnutls.zip
  cp win64-build/bin/*.dll ${TARGET}/bin
}

_prepare
_fetch
_extract
_build
_install
_cmigemo
_pdftools
_dlls

