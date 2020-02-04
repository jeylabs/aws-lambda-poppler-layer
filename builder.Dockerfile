FROM amazonlinux:2018.03

ENV SOURCE_DIR="/opt/jeylabs"
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
    ${INSTALL_DIR}/lib

COPY --from=jeylabs/poppler/compiler:latest ${SOURCE_DIR}/etc/* ${INSTALL_DIR}/etc/
COPY --from=jeylabs/poppler/compiler:latest ${SOURCE_DIR}/bin/* ${INSTALL_DIR}/bin/
COPY --from=jeylabs/poppler/compiler:latest ${SOURCE_DIR}/lib/* ${INSTALL_DIR}/lib/
COPY --from=jeylabs/poppler/compiler:latest ${SOURCE_DIR}/lib64/libuuid.so.1.3.0 ${INSTALL_DIR}/lib/libuuid.so.1

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
