FROM amazonlinux:2

ENV SOURCE_DIR="/opt"
ENV INSTALL_DIR="/opt"

ENV PATH="/opt/bin:${PATH}" \
    LD_LIBRARY_PATH="${INSTALL_DIR}/lib64:${INSTALL_DIR}/lib"

# Install zip

RUN set -xe; \
    LD_LIBRARY_PATH= yum -y install zip

# Copy All Binaries / Libaries

RUN set -xe; \
    mkdir -p ${INSTALL_DIR}/etc \
    ${INSTALL_DIR}/bin \
    ${INSTALL_DIR}/var \
    ${INSTALL_DIR}/share \
    ${INSTALL_DIR}/lib

COPY --from=jeylabs/poppler/compiler:latest /lib64/libuuid.so.* ${INSTALL_DIR}/lib/
COPY --from=jeylabs/poppler/compiler:latest ${SOURCE_DIR}/share/ /tmp/share
COPY --from=jeylabs/poppler/compiler:latest ${SOURCE_DIR}/etc/ ${INSTALL_DIR}/etc/
COPY --from=jeylabs/poppler/compiler:latest ${SOURCE_DIR}/bin/ ${INSTALL_DIR}/bin/
COPY --from=jeylabs/poppler/compiler:latest ${SOURCE_DIR}/var/ ${INSTALL_DIR}/var/
COPY --from=jeylabs/poppler/compiler:latest ${SOURCE_DIR}/lib/ ${INSTALL_DIR}/lib/
COPY --from=jeylabs/poppler/compiler:latest ${SOURCE_DIR}/lib64/ ${INSTALL_DIR}/lib/

RUN set -xe; \
    cp -R /tmp/share/fontconfig ${INSTALL_DIR}/share/fontconfig

# Test file

RUN set -xe; \
    mkdir -p /tmp/test

WORKDIR /tmp/test

RUN set -xe; \
    curl -Ls https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf --output sample.pdf

RUN set -xe; \
    /opt/bin/pdftoppm -png sample.pdf sample

RUN set -xe; \
    test -f /tmp/test/sample-1.png
