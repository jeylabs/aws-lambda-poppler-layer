FROM amazonlinux:latest

SHELL ["/bin/bash", "-c"]

ENV BUILD_DIR="/tmp/build"
ENV INSTALL_DIR="/opt/jeylabs"

# Configure Default Compiler Variables

ENV PKG_CONFIG_PATH="${INSTALL_DIR}/lib64/pkgconfig:${INSTALL_DIR}/lib/pkgconfig" \
    PKG_CONFIG="/usr/bin/pkg-config" \
    PATH="${INSTALL_DIR}/bin:${PATH}"

ENV LD_LIBRARY_PATH="${INSTALL_DIR}/lib64:${INSTALL_DIR}/lib"

# Install Development Tools

RUN set -xe \
    yum makecache \
    && LD_LIBRARY_PATH= yum groupinstall -y "Development Tools" --setopt=group_package_types=mandatory,default

RUN set -xe; \
    LD_LIBRARY_PATH= yum install -y cmake3 gperf libuuid-devel nasm

# Build LibXML2 (https://github.com/GNOME/libxml2/releases)

ENV VERSION_XML2=2.9.9
ENV XML2_BUILD_DIR=${BUILD_DIR}/xml2

RUN set -xe; \
    mkdir -p ${XML2_BUILD_DIR}; \
    curl -Ls http://xmlsoft.org/sources/libxml2-${VERSION_XML2}.tar.gz \
    | tar xzC ${XML2_BUILD_DIR} --strip-components=1

WORKDIR  ${XML2_BUILD_DIR}/

RUN set -xe; \
    ./configure \
    --prefix=${INSTALL_DIR} \
    --with-sysroot=${INSTALL_DIR} \
    --enable-shared \
    --disable-static \
    --with-html \
    --with-history \
    --enable-ipv6=no \
    --with-icu \
    --with-zlib=${INSTALL_DIR} \
    --without-python

RUN set -xe; \
    make

RUN set -xe; \
    make install

RUN set -xe; \
    cp xml2-config ${INSTALL_DIR}/bin/xml2-config

# Install FreeType2 (https://github.com/aseprite/freetype2/releases)

ENV VERSION_FREETYPE2=2.10.1
ENV FREETYPE2_BUILD_DIR=${BUILD_DIR}/freetype2

RUN set -xe; \
    mkdir -p ${FREETYPE2_BUILD_DIR}; \
    curl -Ls https://download-mirror.savannah.gnu.org/releases/freetype/freetype-${VERSION_FREETYPE2}.tar.xz \
    | tar xJvC ${FREETYPE2_BUILD_DIR} --strip-components=1

WORKDIR  ${FREETYPE2_BUILD_DIR}/

RUN set -xe; \
    sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg

RUN set -xe; \
    sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
    -i include/freetype/config/ftoption.h

RUN set -xe; \
    ./configure  \
    --prefix=${INSTALL_DIR} \
    --with-sysroot=${INSTALL_DIR} \
    --enable-freetype-config  \
    --disable-static

RUN set -xe; \
    make

RUN set -xe; \
    make install

# Install Fontconfig (https://github.com/freedesktop/fontconfig/releases)

ENV VERSION_FONTCONFIG=2.13.1
ENV FONTCONFIG_BUILD_DIR=${BUILD_DIR}/fontconfig

RUN set -xe; \
    mkdir -p ${FONTCONFIG_BUILD_DIR}; \
    curl -Ls https://www.freedesktop.org/software/fontconfig/release/fontconfig-${VERSION_FONTCONFIG}.tar.bz2 \
    | tar xjC ${FONTCONFIG_BUILD_DIR} --strip-components=1

WORKDIR  ${FONTCONFIG_BUILD_DIR}/

RUN set -xe; \
    rm -f src/fcobjshash.h

RUN set -xe; \
    ./configure  \
    --prefix=${INSTALL_DIR} \
    --with-sysroot=${INSTALL_DIR} \
    --disable-docs \
    --enable-libxml2

RUN set -xe; \
    make

RUN set -xe; \
    make install

# Install Libjpeg-Turbo (https://github.com/libjpeg-turbo/libjpeg-turbo/releases)

ENV VERSION_LIBJPEG=2.0.3
ENV LIBJPEG_BUILD_DIR=${BUILD_DIR}/libjpeg

RUN set -xe; \
    mkdir -p ${LIBJPEG_BUILD_DIR}/bin; \
    curl -Ls https://ftp.osuosl.org/pub/blfs/conglomeration/libjpeg-turbo/libjpeg-turbo-${VERSION_LIBJPEG}.tar.gz \
    | tar xzC ${LIBJPEG_BUILD_DIR} --strip-components=1

WORKDIR  ${LIBJPEG_BUILD_DIR}/bin/

RUN set -xe; \
    CFLAGS="" \
    CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
    LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
    cmake3 .. \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DENABLE_STATIC=FALSE \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
    -DCMAKE_INSTALL_DEFAULT_LIBDIR=lib

RUN set -xe; \
    make

RUN set -xe; \
    make install

# Install OpenJPEG (https://github.com/uclouvain/openjpeg/releases)

ENV VERSION_OPENJPEG2=2.3.1
ENV OPENJPEG2_BUILD_DIR=${BUILD_DIR}/openjpeg2

RUN set -xe; \
    mkdir -p ${OPENJPEG2_BUILD_DIR}/bin; \
    curl -Ls https://github.com/uclouvain/openjpeg/archive/v${VERSION_OPENJPEG2}/openjpeg-${VERSION_OPENJPEG2}.tar.gz \
    | tar xzC ${OPENJPEG2_BUILD_DIR} --strip-components=1

WORKDIR  ${OPENJPEG2_BUILD_DIR}/bin/

RUN set -xe; \
    CFLAGS="" \
    CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
    LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
    cmake3 .. \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
    -DBUILD_STATIC_LIBS=OFF

RUN set -xe; \
    make

RUN set -xe; \
    make install

# Install Libpng (https://github.com/glennrp/libpng/releases)

ENV VERSION_OPENPNG=1.6.37
ENV OPENPNG_BUILD_DIR=${BUILD_DIR}/libpng

RUN set -xe; \
    mkdir -p ${OPENPNG_BUILD_DIR}; \
    curl -Ls https://downloads.sourceforge.net/libpng/libpng-${VERSION_OPENPNG}.tar.xz \
    | tar xJvC ${OPENPNG_BUILD_DIR} --strip-components=1

WORKDIR  ${OPENPNG_BUILD_DIR}/

RUN set -xe; \
    ./configure  \
    --prefix=${INSTALL_DIR} \
    --disable-static

RUN set -xe; \
    make

RUN set -xe; \
    make install

# Install Pixman (https://www.cairographics.org/releases)

ENV VERSION_PIXMAN=0.38.4
ENV PIXMAN_BUILD_DIR=${BUILD_DIR}/pixman

RUN set -xe; \
    mkdir -p ${PIXMAN_BUILD_DIR}; \
    curl -Ls https://www.cairographics.org/releases/pixman-${VERSION_PIXMAN}.tar.gz \
    | tar xzC ${PIXMAN_BUILD_DIR} --strip-components=1

WORKDIR  ${PIXMAN_BUILD_DIR}/

RUN set -xe; \
    ls -al ${PIXMAN_BUILD_DIR}

RUN set -xe; \
    ./configure  \
    --prefix=${INSTALL_DIR} \
    --disable-static

RUN set -xe; \
    make

RUN set -xe; \
    make install

# Install Cairo (http://www.linuxfromscratch.org/blfs/view/svn/x/cairo.html)

ENV VERSION_CAIRO=1.17.2
ENV CAIRO_BUILD_DIR=${BUILD_DIR}/cairo

RUN set -xe; \
    mkdir -p ${CAIRO_BUILD_DIR}; \
    curl -Ls https://cairographics.org/snapshots/cairo-${VERSION_CAIRO}.tar.xz \
    | tar xJvC ${CAIRO_BUILD_DIR} --strip-components=1

WORKDIR  ${CAIRO_BUILD_DIR}/

RUN set -xe; \
    ./configure  \
    --prefix=${INSTALL_DIR} \
    --disable-static \ 
    --enable-tee

RUN set -xe; \
    make

RUN set -xe; \
    make install

# Install Poppler (https://gitlab.freedesktop.org/poppler/poppler/-/tags)

ENV VERSION_POPPLER=0.83.0
ENV POPPLER_BUILD_DIR=${BUILD_DIR}/poppler
ENV POPPLER_TEST_DIR=${BUILD_DIR}/poppler-test

RUN set -xe; \
    mkdir -p ${POPPLER_TEST_DIR}; \
    git clone git://git.freedesktop.org/git/poppler/test ${POPPLER_TEST_DIR}

RUN set -xe; \
    mkdir -p ${POPPLER_BUILD_DIR}/bin; \
    curl -Ls https://poppler.freedesktop.org/poppler-${VERSION_POPPLER}.tar.xz \
    | tar xJvC ${POPPLER_BUILD_DIR} --strip-components=1

WORKDIR  ${POPPLER_BUILD_DIR}/bin/

RUN set -xe; \
    CFLAGS="" \
    CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
    LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
    cmake3 .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DTESTDATADIR=${POPPLER_TEST_DIR} \
    -DENABLE_UNSTABLE_API_ABI_HEADERS=ON \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}

RUN set -xe; \
    make

RUN set -xe; \
    make install
