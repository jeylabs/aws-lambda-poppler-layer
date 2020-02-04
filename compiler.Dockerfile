FROM amazonlinux:2018.03

SHELL ["/bin/bash", "-c"]

ENV BUILD_DIR="/tmp/build"
ENV INSTALL_DIR="/opt/jeylabs"

# Lock To Proper Release

RUN sed -i 's/releasever=latest/releaserver=2018.03/' /etc/yum.conf

# Create All The Necessary Build Directories

RUN mkdir -p ${BUILD_DIR}  \
    ${INSTALL_DIR}/bin \
    ${INSTALL_DIR}/doc \
    ${INSTALL_DIR}/include \
    ${INSTALL_DIR}/lib \
    ${INSTALL_DIR}/lib64 \
    ${INSTALL_DIR}/libexec \
    ${INSTALL_DIR}/sbin \
    ${INSTALL_DIR}/share

# Install Development Tools

WORKDIR /tmp

RUN set -xe \
    && yum makecache \
    && yum groupinstall -y "Development Tools"  --setopt=group_package_types=mandatory,default \
    && yum install -y libuuid-devel

RUN set -xe \
    mv /usr/lib64/libuuid.so.1 ${INSTALL_DIR}/lib64/

# Install CMake

RUN  set -xe \
    && mkdir -p /tmp/cmake \
    && cd /tmp/cmake \
    && curl -Ls  https://github.com/Kitware/CMake/releases/download/v3.13.2/cmake-3.13.2.tar.gz \
    | tar xzC /tmp/cmake --strip-components=1 \
    && ./bootstrap --prefix=/usr/local \
    && make \
    && make install

# Install NASM

RUN  set -xe \
    && mkdir -p /tmp/nasm \
    && cd /tmp/nasm \
    && curl -Ls  http://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.xz \
    | tar xJvC /tmp/nasm --strip-components=1 \
    && ./configure --prefix=/usr/local \
    && make \
    && make install

# Configure Default Compiler Variables

ENV PKG_CONFIG_PATH="${INSTALL_DIR}/lib64/pkgconfig:${INSTALL_DIR}/lib/pkgconfig" \
    PKG_CONFIG="/usr/bin/pkg-config" \
    PATH="${INSTALL_DIR}/bin:${PATH}"

ENV LD_LIBRARY_PATH="${INSTALL_DIR}/lib64:${INSTALL_DIR}/lib"

# Build LibXML2 (https://github.com/GNOME/libxml2/releases)

ENV VERSION_XML2=2.9.9
ENV XML2_BUILD_DIR=${BUILD_DIR}/xml2

RUN set -xe; \
    mkdir -p ${XML2_BUILD_DIR}; \
    curl -Ls http://xmlsoft.org/sources/libxml2-${VERSION_XML2}.tar.gz \
    | tar xzC ${XML2_BUILD_DIR} --strip-components=1

WORKDIR  ${XML2_BUILD_DIR}/

RUN set -xe; \
    CFLAGS="" \
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
    --without-python

RUN set -xe; \
    make install \
    && cp xml2-config ${INSTALL_DIR}/bin/xml2-config

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
    CFLAGS="" \
    CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
    LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
    ./configure  \
    --prefix=${INSTALL_DIR} \
    --with-sysroot=${INSTALL_DIR} \
    --enable-freetype-config  \
    --disable-static \ 
    && make \
    && make install

# Install gperf

ENV VERSION_GPERF=3.1
ENV GPERF_BUILD_DIR=${BUILD_DIR}/gperf

RUN set -xe; \
    mkdir -p ${GPERF_BUILD_DIR}; \
    curl -Ls http://ftp.gnu.org/pub/gnu/gperf/gperf-${VERSION_GPERF}.tar.gz \
    | tar xzC ${GPERF_BUILD_DIR} --strip-components=1

WORKDIR  ${GPERF_BUILD_DIR}/

RUN set -xe; \
    CFLAGS="" \
    CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
    LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
    ./configure  \
    --prefix=${INSTALL_DIR} \
    && make \
    && make install

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
    CFLAGS="" \
    CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
    LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
    ./configure  \
    --prefix=${INSTALL_DIR} \
    --disable-docs \
    --enable-libxml2 \
    && make \
    && make install

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
    cmake .. \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DENABLE_STATIC=FALSE \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
    -DCMAKE_INSTALL_DEFAULT_LIBDIR=lib \ 
    && make \
    && make install

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
    cmake .. \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
    -DBUILD_STATIC_LIBS=OFF \ 
    && make \
    && make install

# Install Libpng (https://github.com/glennrp/libpng/releases)

ENV VERSION_OPENPNG=1.6.37
ENV OPENPNG_BUILD_DIR=${BUILD_DIR}/libpng

RUN set -xe; \
    mkdir -p ${OPENPNG_BUILD_DIR}; \
    curl -Ls https://downloads.sourceforge.net/libpng/libpng-${VERSION_OPENPNG}.tar.xz \
    | tar xJvC ${OPENPNG_BUILD_DIR} --strip-components=1

WORKDIR  ${OPENPNG_BUILD_DIR}/

RUN set -xe; \
    CFLAGS="" \
    CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
    LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
    ./configure  \
    --prefix=${INSTALL_DIR} \
    --disable-static \ 
    && make \
    && make install

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
    CFLAGS="" \
    CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
    LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
    ./configure  \
    --prefix=${INSTALL_DIR} \
    --disable-static \ 
    && make \
    && make install

# Install Cairo (http://www.linuxfromscratch.org/blfs/view/svn/x/cairo.html)

ENV VERSION_CAIRO=1.17.2
ENV CAIRO_BUILD_DIR=${BUILD_DIR}/cairo

RUN set -xe; \
    mkdir -p ${CAIRO_BUILD_DIR}; \
    curl -Ls https://cairographics.org/snapshots/cairo-${VERSION_CAIRO}.tar.xz \
    | tar xJvC ${CAIRO_BUILD_DIR} --strip-components=1

WORKDIR  ${CAIRO_BUILD_DIR}/

RUN set -xe; \
    CFLAGS="" \
    CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
    LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
    ./configure  \
    --prefix=${INSTALL_DIR} \
    --disable-static \ 
    --enable-tee \ 
    && make \
    && make install

# Install qt5 (https://wiki.qt.io/Qt_5.12_Release)

ENV VERSION_QT=5.14.1
ENV QT_BUILD_DIR=${BUILD_DIR}/qt5

RUN set -xe; \
    mkdir -p ${QT_BUILD_DIR}; \
    curl -Ls https://download.qt.io/archive/qt/5.14/${VERSION_QT}/single/qt-everywhere-src-${VERSION_QT}.tar.xz \
    | tar xJvC ${QT_BUILD_DIR} --strip-components=1

WORKDIR  ${QT_BUILD_DIR}/

RUN set -xe; \
    export CXXFLAGS="$CXXFLAGS -std=c++11"  \
    && sed -i 's/QMAKE_CXXFLAGS = @CFLAGS@ @CPPFLAGS@$/QMAKE_CXXFLAGS = @CFLAGS@ @CPPFLAGS@ @CXXFLAGS@/' ./OMEdit/OMEdit/OMEditGUI/OMEdit.config.in  \
    && sed -i 's/QMAKE_CXXFLAGS = @CFLAGS@ @CPPFLAGS@$/QMAKE_CXXFLAGS = @CFLAGS@ @CPPFLAGS@ @CXXFLAGS@/' ./OMNotebook/OMNotebook/OMNotebookGUI/OMNotebook.config.in  \
    && sed -i 's/QMAKE_CXXFLAGS = @CFLAGS@ @CPPFLAGS@$/QMAKE_CXXFLAGS = @CFLAGS@ @CPPFLAGS@ @CXXFLAGS@/' ./OMShell/OMShell/OMShellGUI/OMShell.config.in  \
    && sed -i 's/QMAKE_CXXFLAGS = @CFLAGS@ @CPPFLAGS@$/QMAKE_CXXFLAGS = @CFLAGS@ @CPPFLAGS@ @CXXFLAGS@/' ./OMPlot/OMPlot/OMPlotGUI/OMPlotGUI.config.in  \
    && sed -i 's/#QMAKE_CXXFLAGS   \*= -std=c++11$/QMAKE_CXXFLAGS   *= -std=c++11/' ./OMPlot/qwt/qwtbuild.pri

RUN set -xe; \
    CFLAGS="" \
    QT5PREFIX=${INSTALL_DIR}/qt5 \
    CPPFLAGS="-I${INSTALL_DIR}/include  -I/usr/include" \
    LDFLAGS="-L${INSTALL_DIR}/lib64 -L${INSTALL_DIR}/lib" \
    ./configure  \
    -prefix ${INSTALL_DIR}/qt5 \
    -confirm-license    \
    -opensource \
    -nomake examples    \
    -no-rpath   \
    -no-opengl \
    -skip qtwebengine   \
    && make \
    && make install

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
    cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DTESTDATADIR=${POPPLER_TEST_DIR} \
    -DENABLE_UNSTABLE_API_ABI_HEADERS=ON \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \ 
    && make \
    && make install

# Symlink All Binaries / Libaries

RUN mkdir -p /opt/bin
RUN mkdir -p /opt/lib

RUN cp /opt/vapor/bin/* /opt/bin
RUN cp /opt/vapor/sbin/* /opt/bin

RUN cp /opt/vapor/lib/* /opt/lib || true
RUN cp /opt/vapor/lib64/* /opt/lib || true

RUN ls /opt/bin
