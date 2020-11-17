FROM lambci/lambda-base-2:build AS compile

ENV BUILD_DIR="/tmp/build"
ENV INSTALL_DIR="/opt"

# Create all necessary build directories
#
RUN set -Eeuxo pipefail \
    && mkdir -p ${BUILD_DIR}/{etc,bin,doc,include,lib,lib64,libexec,sbin,share}

# Install Development Tools
#
WORKDIR /tmp

RUN set -Eeuxo pipefail \
    && yum -y update \
    && yum -y install \
    cmake3 \
    # libuuid is required by Fontconfig
    libuuid-devel \
    nasm \
    ninja-build \
    openssl-devel \
    && yum -y clean all

RUN pip3 install meson


# Configure Default Compiler Variables
#
ENV PKG_CONFIG_PATH="${INSTALL_DIR}/lib64/pkgconfig:${INSTALL_DIR}/lib/pkgconfig" \
    PKG_CONFIG="/usr/bin/pkg-config" \
    PATH="${INSTALL_DIR}/bin:${PATH}"

ENV LD_LIBRARY_PATH="${INSTALL_DIR}/lib64:${INSTALL_DIR}/lib"


# Install LibXML2 (https://github.com/GNOME/libxml2/releases)
#
# Pre-installed on Amazon Linux: no
# Required by: Fontconfig
#
ENV XML2_VERSION=2.9.10
ENV XML2_BUILD_DIR=${BUILD_DIR}/xml2

RUN set -Eeuxo pipefail \
    && mkdir -p ${XML2_BUILD_DIR} \
    && curl -Ls http://xmlsoft.org/sources/libxml2-${XML2_VERSION}.tar.gz \
    | tar xzC ${XML2_BUILD_DIR} --strip-components=1

WORKDIR  ${XML2_BUILD_DIR}/

RUN set -Eeuxo pipefail \
    && CFLAGS="" \
    CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
    LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
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
    --without-python \
    && make install \
    && cp xml2-config ${INSTALL_DIR}/bin/xml2-config


# Install GLib (http://www.linuxfromscratch.org/blfs/view/svn/general/cmake.html)
#
# Pre-installed on Amazon Linux: 2.36.3
# Required by: Poppler
# Note: Amazon Linux has GLib 2.36.3 but Poppler requires >=2.41.0
#
ENV GLIB_VERSION=2.64.4
ENV GLIB_MAJOR=2.64
ENV GLIB_BUILD_DIR=${BUILD_DIR}/glib

RUN set -Eeuxo pipefail \
    && mkdir -p ${GLIB_BUILD_DIR} \
    && curl -L http://ftp.gnome.org/pub/gnome/sources/glib/${GLIB_MAJOR}/glib-${GLIB_VERSION}.tar.xz \
    | tar xJC ${GLIB_BUILD_DIR} --strip-components=1

WORKDIR ${GLIB_BUILD_DIR}

RUN set -Eeuxo pipefail \
    && mkdir build \
    && cd build \
    && meson \
    --prefix=${INSTALL_DIR} \
    -Dselinux=disabled \
    && ninja-build \
    && ninja-build install


# Install Libpng (http://www.linuxfromscratch.org/blfs/view/svn/general/openjpeg2.html)
#
# Pre-installed on Amazon Linux: 1.2.49
# Required by: Cairo (Poppler)
# Recommended by: Poppler, FreeType (Poppler)
# Optional by: libvips
#
ENV LIBPNG_VERSION=1.6.37
ENV LIBPNG_BUILD_DIR=${BUILD_DIR}/libpng

RUN set -Eeuxo pipefail \
    && mkdir -p ${LIBPNG_BUILD_DIR} \
    && curl -L https://downloads.sourceforge.net/libpng/libpng-${LIBPNG_VERSION}.tar.xz \
    | tar xJC ${LIBPNG_BUILD_DIR} --strip-components=1

WORKDIR ${LIBPNG_BUILD_DIR}/

RUN set -Eeuxo pipefail \
    && ./configure  \
    --prefix=${INSTALL_DIR} \
    --disable-static \
    && make V=0 \
    && make install


# Install Libjpeg-Turbo (http://www.linuxfromscratch.org/blfs/view/svn/general/libjpeg.html)
#
# Pre-installed on Amazon Linux: no
# Recommended by: Poppler
# Optional by: libvips
#
ENV LIBJPEG_TURBO_VERSION=2.0.5
ENV LIBJPEG_TURBO_BUILD_DIR=${BUILD_DIR}/libjpeg

RUN set -Eeuxo pipefail \
    && mkdir -p ${LIBJPEG_TURBO_BUILD_DIR}/build \
    && curl -L https://downloads.sourceforge.net/libjpeg-turbo/libjpeg-turbo-${LIBJPEG_TURBO_VERSION}.tar.gz \
    | tar xzC ${LIBJPEG_TURBO_BUILD_DIR} --strip-components=1

WORKDIR ${LIBJPEG_TURBO_BUILD_DIR}/build/

RUN set -Eeuxo pipefail \
    && cmake3 .. \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DENABLE_STATIC=FALSE \
    -DCMAKE_INSTALL_DEFAULT_LIBDIR=lib \
    && make V=0 \
    && make install


# Install OpenJPEG (http://www.linuxfromscratch.org/blfs/view/svn/general/openjpeg2.html)
#
# Pre-installed on Amazon Linux: no
# Recommended by: Poppler
#
ENV OPENJPEG_VERSION=2.3.1
ENV OPENJPEG_BUILD_DIR=${BUILD_DIR}/openjpeg2

RUN set -Eeuxo pipefail \
    && mkdir -p ${OPENJPEG_BUILD_DIR}/build \
    && curl -L https://github.com/uclouvain/openjpeg/archive/v${OPENJPEG_VERSION}/openjpeg-${OPENJPEG_VERSION}.tar.gz \
    | tar xzC ${OPENJPEG_BUILD_DIR} --strip-components=1

WORKDIR ${OPENJPEG_BUILD_DIR}/build/

RUN set -Eeuxo pipefail \
    && cmake3 .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
    -DBUILD_STATIC_LIBS=OFF \
    && make V=0 \
    && make install


# Install FreeType (http://www.linuxfromscratch.org/blfs/view/svn/general/freetype2.html)
#
# Pre-installed on Amazon Linux: 2.3.11
# Required by: Fontconfig (Poppler)
#
ENV FREETYPE_VERSION=2.10.4
ENV FREETYPE_BUILD_DIR=${BUILD_DIR}/freetype

RUN set -Eeuxo pipefail \
    && mkdir -p ${FREETYPE_BUILD_DIR} \
    && curl -L https://download-mirror.savannah.gnu.org/releases/freetype/freetype-${FREETYPE_VERSION}.tar.xz \
    | tar xJC ${FREETYPE_BUILD_DIR} --strip-components=1

WORKDIR ${FREETYPE_BUILD_DIR}/

RUN set -Eeuxo pipefail \
    && sed -r "s:.*(AUX_MODULES.*valid):\1:" -i modules.cfg \
    && sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" -i include/freetype/config/ftoption.h

RUN set -Eeuxo pipefail \
    && ./configure  \
    --prefix=${INSTALL_DIR} \
    --with-sysroot=${INSTALL_DIR} \
    --enable-freetype-config  \
    --disable-static \
    && make V=0 \
    && make install


# Install Harfbuzz (http://www.linuxfromscratch.org/blfs/view/svn/general/harfbuzz.html)
#
# Pre-installed on Amazon Linux: no
# Recommended by: FreeType
#
ENV HARZBUFF_VERSION=2.7.0
ENV HARZBUFF_BUILD_DIR=${BUILD_DIR}/harfbuzz

RUN set -Eeuxo pipefail \
    && mkdir -p ${HARZBUFF_BUILD_DIR} \
    && curl -L https://github.com/harfbuzz/harfbuzz/archive/${HARZBUFF_VERSION}.tar.gz \
    | tar xzC ${HARZBUFF_BUILD_DIR} --strip-components=1

WORKDIR ${HARZBUFF_BUILD_DIR}/

RUN set -Eeuxo pipefail \
    && mkdir build \
    && cd build \
    && meson \
    --prefix=${INSTALL_DIR} \
    && ninja-build \
    && ninja-build install

# Now re-install FreeType

WORKDIR ${FREETYPE_BUILD_DIR}/

RUN set -Eeuxo pipefail \
    && ./configure  \
    --prefix=${INSTALL_DIR} \
    --with-sysroot=${INSTALL_DIR} \
    --enable-freetype-config  \
    --disable-static \
    && make V=0 \
    && make install


# Install Gperf (http://www.linuxfromscratch.org/blfs/view/7.4/general/gperf.html)
#
# Pre-installed on Amazon Linux: no
# Required by: Fontconfig
#
ENV GPERF_VERSION=3.1
ENV GPERF_BUILD_DIR=${BUILD_DIR}/gperf

RUN set -Eeuxo pipefail \
    && mkdir -p ${GPERF_BUILD_DIR} \
    && curl -L http://ftp.gnu.org/pub/gnu/gperf/gperf-${GPERF_VERSION}.tar.gz \
    | tar xzC ${GPERF_BUILD_DIR} --strip-components=1

WORKDIR  ${GPERF_BUILD_DIR}/

RUN set -Eeuxo pipefail \
    && ./configure  \
    --prefix=${INSTALL_DIR} \
    && make V=0 \
    && make install


# Install Fontconfig (http://www.linuxfromscratch.org/blfs/view/svn/general/fontconfig.html)
#
# Pre-installed on Amazon Linux: 2.8.0
# Required by: Poppler
# Requires: freetype and either expat or libxml2 (http://bio.gsi.de/DOCS/SOFTWARE/fontconfig.html) - not sure if that's still the case
#
ENV FONTCONFIG_VERSION=2.13.1
ENV FONTCONFIG_BUILD_DIR=${BUILD_DIR}/fontconfig

RUN set -Eeuxo pipefail \
    && mkdir -p ${FONTCONFIG_BUILD_DIR} \
    && curl -L https://www.freedesktop.org/software/fontconfig/release/fontconfig-${FONTCONFIG_VERSION}.tar.bz2 \
    | tar xjC ${FONTCONFIG_BUILD_DIR} --strip-components=1

WORKDIR ${FONTCONFIG_BUILD_DIR}/

RUN set -Eeuxo pipefail \
    && rm -f src/fcobjshash.h

RUN set -Eeuxo pipefail \
    && LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
    FONTCONFIG_PATH=${INSTALL_DIR} \
    ./configure  \
    --sysconfdir=${INSTALL_DIR}/etc \
    --localstatedir=${INSTALL_DIR}/var \
    --prefix=${INSTALL_DIR} \
    --disable-docs \
    --enable-libxml2 \
    && make V=0 \
    && make install


# Install Pixman (http://www.linuxfromscratch.org/blfs/view/svn/general/pixman.html)
#
# Pre-installed on Amazon Linux: 0.32.4
# Required by: Cairo (Poppler)
#
ENV PIXMAN_VERSION=0.40.0
ENV PIXMAN_BUILD_DIR=${BUILD_DIR}/pixman

RUN set -Eeuxo pipefail \
    && mkdir -p ${PIXMAN_BUILD_DIR} \
    && curl -L https://www.cairographics.org/releases/pixman-${PIXMAN_VERSION}.tar.gz \
    | tar xzC ${PIXMAN_BUILD_DIR} --strip-components=1

WORKDIR ${PIXMAN_BUILD_DIR}/

RUN set -Eeuxo pipefail \
    && mkdir build \
    && cd build \
    && meson --prefix=${INSTALL_DIR} \
    && ninja-build \
    && ninja-build install


# Install Cairo (http://www.linuxfromscratch.org/blfs/view/svn/x/cairo.html)
#
# Pre-installed on Amazon Linux: 1.12.14
# Recommended by: Poppler
#
ENV CAIRO_VERSION=1.17.2
ENV CAIRO_BUILD_DIR=${BUILD_DIR}/cairo

RUN set -Eeuxo pipefail \
    && mkdir -p ${CAIRO_BUILD_DIR} \
    && curl -L https://cairographics.org/snapshots/cairo-${CAIRO_VERSION}.tar.xz \
    | tar xJC ${CAIRO_BUILD_DIR} --strip-components=1

WORKDIR ${CAIRO_BUILD_DIR}/

RUN set -Eeuxo pipefail \
    && autoreconf -fiv \
    && ./configure \
    --prefix=${INSTALL_DIR} \
    --disable-static \
    --enable-tee \
    && make \
    && make install


# Install Little CMS (http://www.linuxfromscratch.org/blfs/view/svn/general/lcms2.html)
#
# Pre-installed on Amazon Linux: 2.6
# Recommended by: Poppler
# Optional by: libvips
#
ENV LCMS2_VERSION=2.11
ENV LCMS2_BUILD_DIR=${BUILD_DIR}/lcms

RUN set -Eeuxo pipefail \
    && mkdir -p ${LCMS2_BUILD_DIR} \
    && curl -L https://downloads.sourceforge.net/lcms/lcms2-${LCMS2_VERSION}.tar.gz \
    | tar xzC ${LCMS2_BUILD_DIR} --strip-components=1

WORKDIR ${LCMS2_BUILD_DIR}/

RUN set -Eeuxo pipefail \
    && ./configure  \
    --prefix=${INSTALL_DIR} \
    --disable-static \
    && make V=0 \
    && make install


# Install Boost (http://www.linuxfromscratch.org/blfs/view/svn/general/boost.html)
#
# Pre-installed on Amazon Linux: no
# Optional by: Poppler
#
ENV BOOST_VERSION=1.74.0
ENV BOOST_BUILD_DIR=${BUILD_DIR}/boost

RUN set -Eeuxo pipefail \
    && mkdir -p ${BOOST_BUILD_DIR} \
    && curl -L https://dl.bintray.com/boostorg/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION//./_}.tar.bz2 \
    | tar xjC ${BOOST_BUILD_DIR} --strip-components=1

WORKDIR ${BOOST_BUILD_DIR}/

RUN set -Eeuxo pipefail \
    && ./bootstrap.sh \
    --prefix=${INSTALL_DIR} \
    && ./b2 stage -j4 threading=multi link=shared \
    && ./b2 install threading=multi link=shared


# Install Poppler (http://www.linuxfromscratch.org/blfs/view/svn/general/poppler.html)
#
# Pre-installed on Amazon Linux: no
#
ENV POPPLER_VERSION=20.11.0
ENV POPPLER_BUILD_DIR=${BUILD_DIR}/poppler

RUN set -Eeuxo pipefail \
    && mkdir -p ${POPPLER_BUILD_DIR}/build \
    && curl -L https://poppler.freedesktop.org/poppler-${POPPLER_VERSION}.tar.xz \
    | tar xJC ${POPPLER_BUILD_DIR} --strip-components=1

WORKDIR ${POPPLER_BUILD_DIR}/build/

RUN set -Eeuxo pipefail \
    && LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
    cmake3 .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
    -DENABLE_UNSTABLE_API_ABI_HEADERS=ON \
    -DENABLE_GLIB=ON \
    -DENABLE_CPP=OFF \
    -DENABLE_QT5=OFF \
    -DENABLE_SPLASH=ON \
    -DPNG_INCLUDE_DIR=${INSTALL_DIR}/include \
    -DPNG_LIBRARIES=${INSTALL_DIR}/lib64 \
    && make V=0 \
    && make install

FROM lambci/lambda-base-2:build AS runtime

ENV SOURCE_DIR="/opt"
ENV INSTALL_DIR="/opt"

ENV PATH="/opt/bin:${PATH}" \
    LD_LIBRARY_PATH="${INSTALL_DIR}/lib64:${INSTALL_DIR}/lib"

# Install zip
#
RUN set -Eeuxo pipefail \
    && yum update -y \
    && yum -y install zip \
    && yum -y clean all

# Copy all binaries/libaries
COPY --from=compile /usr/lib64/libuuid.so* ${INSTALL_DIR}/lib/
COPY --from=compile /usr/lib64/libexpat.so* ${INSTALL_DIR}/lib/
COPY --from=compile ${SOURCE_DIR}/bin/ ${INSTALL_DIR}/bin/
COPY --from=compile ${SOURCE_DIR}/etc/ ${INSTALL_DIR}/etc/
COPY --from=compile ${SOURCE_DIR}/lib/ ${INSTALL_DIR}/lib/
COPY --from=compile ${SOURCE_DIR}/lib64/ ${INSTALL_DIR}/lib/
COPY --from=compile ${SOURCE_DIR}/share/fontconfig ${INSTALL_DIR}/share/fontconfig
COPY --from=compile ${SOURCE_DIR}/var/ ${INSTALL_DIR}/var/

FROM runtime AS test

# Test file
#
RUN set -Eeuxo pipefail \
    && cd /tmp \
    && curl -Ls https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf --output sample.pdf \
    && /opt/bin/pdftoppm -png sample.pdf sample \
    && test -f sample-1.png \
    && rm *.pdf *.png
