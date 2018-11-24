# Ubuntu and Bitcoin Core versions
FROM ubuntu:18.04
ENV BITCOIN_CORE_VER=0.17.0.1

# Install basic tools
RUN apt-get update && apt-get install -y \
	git \
	wget \
	build-essential \
	&& rm -rf /var/lib/apt/lists/*

# Download Bitcoin Core
RUN git clone --progress --verbose https://github.com/bitcoin/bitcoin.git

# Run script to install libdb4.8 (Berkeley DB)
WORKDIR /
RUN ./bitcoin/contrib/install_db4.sh .
RUN rm db-4.8.30.NC.tar.gz
ENV BDB_PREFIX=/db4

# Install dependencies for cross-compile
RUN apt-get update && apt-get install -y \
	curl \
	libtool \
	autotools-dev \
	automake \
        pkg-config \
	bsdmainutils \
	python3 \
	libssl-dev \
	libevent-dev \
        libboost-all-dev \
	libminiupnpc-dev \
	libzmq3-dev \
	libprotobuf-dev \
	protobuf-compiler \
	doxygen \
	&& rm -rf /var/lib/apt/lists/*

# Checkout current release tag and create installation directory
WORKDIR /bitcoin
RUN git checkout v${BITCOIN_CORE_VER} && mkdir -p /bitcoin/bitcoin-${BITCOIN_CORE_VER}

# Build dependencies for the current arch+OS
WORKDIR /bitcoin/depends
RUN make
ENV CONF_PREFIX=/bitcoin/depends/x86_64-pc-linux-gnu

# Build Bitcoin Core
WORKDIR /bitcoin
RUN ./autogen.sh
RUN ./configure --with-gui \
	--host=x86_64-pc-linux-gnu \
	--prefix=${CONF_PREFIX} \
	CPPFLAGS="-I${BDB_PREFIX}/include/ -O2" \
	LDFLAGS="-L${BDB_PREFIX}/lib/"
RUN make

# Install Bitcoin Core
RUN make install DESTDIR=/bitcoin/bitcoin-${BITCOIN_CORE_VER}
RUN mv /bitcoin/bitcoin-${BITCOIN_CORE_VER}${CONF_PREFIX} /bitcoin-${BITCOIN_CORE_VER}
RUN strip /bitcoin-${BITCOIN_CORE_VER}/bin/*
RUN rm -rf /bitcoin-${BITCOIN_CORE_VER}/lib/pkgconfig
RUN find /bitcoin-${BITCOIN_CORE_VER} -name "lib*.la" -delete
RUN find /bitcoin-${BITCOIN_CORE_VER} -name "lib*.a" -delete

# Tarball Bitcoin Core
WORKDIR /
RUN tar -zcvf bitcoin-${BITCOIN_CORE_VER}-btcweekend.tar.gz bitcoin-${BITCOIN_CORE_VER}
