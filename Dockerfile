FROM postgres:10-alpine

ENV POSTGIS_VERSION 2.5.3
ENV POSTGIS_SHA256 402323c83d97f3859bc9083345dd687f933c261efe0830e1262c20c12671f794
ENV CSTORE_VERSION 1.6.1
ENV CSTORE_SHA256 8f9e9f4edc7c816e87c4273169a4a405fdf9f53b42f6f8f956875c4115ea2392

RUN set -ex \
    \
    && apk add --no-cache --virtual .fetch-deps \
        ca-certificates \
        openssl \
        tar \
    \
    && wget -O postgis.tar.gz "https://github.com/postgis/postgis/archive/$POSTGIS_VERSION.tar.gz" \
    && echo "$POSTGIS_SHA256 *postgis.tar.gz" | sha256sum -c - \
    && mkdir -p /usr/src/postgis \
    && tar \
        --extract \
        --file postgis.tar.gz \
        --directory /usr/src/postgis \
        --strip-components 1 \
    && rm postgis.tar.gz \
    \
    && apk add --no-cache --virtual .build-deps \
        autoconf \
        automake \
        g++ \
        json-c-dev \
        libtool \
        libxml2-dev \
        make \
        perl \
        coreutils \
    \
    && apk add --no-cache --virtual .build-deps-testing \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        gdal-dev \
        geos-dev \
        proj-dev \
        protobuf-c-dev \
    && cd /usr/src/postgis \
    && ./autogen.sh \
# configure options taken from:
# https://anonscm.debian.org/cgit/pkg-grass/postgis.git/tree/debian/rules?h=jessie
    && ./configure \
#       --with-gui \
    && make \
    && make install \
    && apk add --no-cache --virtual .postgis-rundeps \
        json-c \
    && apk add --no-cache --virtual .postgis-rundeps-testing \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        geos \
        gdal \
        proj \
        protobuf-c \
    && cd / \
    && rm -rf /usr/src/postgis \
# Install cstore
    && wget -O cstore_fdw.tar.gz "https://github.com/citusdata/cstore_fdw/archive/v${CSTORE_VERSION}.tar.gz" \
    && echo "${CSTORE_SHA256} *cstore_fdw.tar.gz" | sha256sum -c - \
    && mkdir -p /usr/src/cstore_fdw \
    && tar \
        --extract \
        --file cstore_fdw.tar.gz \
        --directory /usr/src/cstore_fdw \
        --strip-components 1 \
    && rm cstore_fdw.tar.gz \
    && cd /usr/src/cstore_fdw \
    && make \
    && make install \
    && sed "s/#shared_preload_libraries = ''/shared_preload_libraries = 'cstore_fdw'/g" /usr/local/share/postgresql/postgresql.conf.sample -i \
# Clean deps
    && apk del .fetch-deps .build-deps .build-deps-testing

COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/postgis.sh
COPY ./initdb-cstore.sh /docker-entrypoint-initdb.d/cstore.sh
COPY ./update-postgis.sh /usr/local/bin