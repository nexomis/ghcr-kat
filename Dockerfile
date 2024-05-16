# Stage 1: Build environment
FROM ubuntu:20.04 as builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
    autoconf \
    automake \
    make \
    gcc \
    g++ \
    libc6-dev \
    libtool \
    python3-dev \
    zlib1g-dev \
    wget \
    python3-numpy \
    python3-scipy \
    python3-matplotlib \
    python3-sphinx \
    python3-distutils \
    python3-setuptools \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /opt/kat \
    && chmod o+rx /opt /opt/kat

# Clone KAT repository
WORKDIR /build
RUN wget https://github.com/TGAC/KAT/archive/refs/tags/Release-2.4.1.tar.gz \
  && tar xvzf Release-2.4.1.tar.gz 

# Build KAT
WORKDIR /build/KAT-Release-2.4.1
RUN ./build_boost.sh
RUN ./autogen.sh
RUN ./configure --prefix /opt/kat
RUN make
RUN make install

# Stage 2: Runtime environment
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
    zlib1g \
    python3 \
    libpython3.8 \
    libtool \
    libc6 \
    python3-numpy \
    python3-scipy \
    python3-matplotlib \
    python3-sphinx \
    python3-distutils \
    python3-setuptools \
    python3-tabulate \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /opt/kat \
    && chmod o+rx /opt /opt/kat

# Copy the built KAT binaries from the builder stage
COPY --from=builder /opt/kat/bin /opt/kat/bin
COPY --from=builder /opt/kat/lib /opt/kat/lib

RUN ln -s /opt/kat/lib/python3.8/site-packages /usr/local/lib/python3.8/site-packages

# Set the environment variable to find shared libraries
ENV LD_LIBRARY_PATH=/opt/kat/lib:$LD_LIBRARY_PATH
ENV PATH=/opt/kat/bin:$PATH

# Define the default command to run KAT
ENTRYPOINT ["/opt/kat/bin/kat"]
