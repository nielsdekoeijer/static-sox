# =============================================================================
# Use Debian Bookworm as the base image
FROM debian:bookworm AS builder_x64

# Install system dependencies
RUN apt-get update && apt-get install -y \
    cmake \
    git \
    wget \
    build-essential \
    ninja-build \
    xxd \
    curl \
    pkg-config \
    libtool \
    autoconf \
    automake \
    autoconf-archive \
    sed \
    && rm -rf /var/lib/apt/lists/*

# Get MUSL
WORKDIR /toolchains
RUN curl http://musl.cc/x86_64-linux-musl-cross.tgz \
  --output x86_64-linux-musl-cross.tgz
RUN tar xvzf x86_64-linux-musl-cross.tgz 
RUN rm x86_64-linux-musl-cross.tgz

# Setup env
ENV CC=/toolchains/x86_64-linux-musl-cross/bin/x86_64-linux-musl-gcc 
ENV CXX=/toolchains/x86_64-linux-musl-cross/bin/x86_64-linux-musl-g++
ENV STRIP=/toolchains/x86_64-linux-musl-cross/bin/x86_64-linux-musl-strip
ENV AR=/toolchains/x86_64-linux-musl-cross/bin/x86_64-linux-musl-ar
ENV SYSROOT=/toolchains/x86_64-linux-musl-cross
ENV CFLAGS="-Wno-error -static"
ENV CXXFLAGS="-Wno-error -static"
ENV LDFLAGS="-static -static-libgcc"

# Set the working directory
WORKDIR /workspace
RUN git clone https://github.com/chirlu/sox.git

WORKDIR /workspace/sox
RUN autoupdate
RUN autoreconf -i
RUN ./configure --host=x86_64-linux-musl --disable-shared LDFLAGS="-static"
RUN sed -i '480d' "./src/formats.c"
RUN VERBOSE=1 make LDFLAGS="-all-static"

# =============================================================================
# Use Debian Bookworm as the base image
FROM debian:bookworm AS builder_a64

# Install system dependencies
RUN apt-get update && apt-get install -y \
    cmake \
    git \
    wget \
    build-essential \
    ninja-build \
    xxd \
    curl \
    pkg-config \
    libtool \
    autoconf \
    automake \
    autoconf-archive \
    sed \
    && rm -rf /var/lib/apt/lists/*

# Get MUSL
WORKDIR /toolchains
RUN curl http://musl.cc/aarch64-linux-musl-cross.tgz \
  --output aarch64-linux-musl-cross.tgz
RUN tar xvzf aarch64-linux-musl-cross.tgz 
RUN rm aarch64-linux-musl-cross.tgz

# setup env
ENV CC=/toolchains/aarch64-linux-musl-cross/bin/aarch64-linux-musl-gcc 
ENV CXX=/toolchains/aarch64-linux-musl-cross/bin/aarch64-linux-musl-g++
ENV STRIP=/toolchains/aarch64-linux-musl-cross/bin/aarch64-linux-musl-strip
ENV AR=/toolchains/aarch64-linux-musl-cross/bin/aarch64-linux-musl-ar
ENV SYSROOT=/toolchains/aarch64-linux-musl-cross/
ENV CFLAGS="-Wno-error -static"
ENV CXXFLAGS="-Wno-error -static"
ENV LDFLAGS="-static -static-libgcc"

# Set the working directory
WORKDIR /workspace
RUN git clone https://github.com/chirlu/sox.git

WORKDIR /workspace/sox
RUN autoupdate
RUN autoreconf -i
RUN ./configure --host=aarch64-linux-musl --disable-shared LDFLAGS="-static"
RUN sed -i '480d' "./src/formats.c"
RUN VERBOSE=1 make LDFLAGS="-all-static"

# =============================================================================
from scratch as writer
COPY --from=builder_x64 /workspace/sox/src/sox ./sox_x86
COPY --from=builder_a64 /workspace/sox/src/sox ./sox_a64

