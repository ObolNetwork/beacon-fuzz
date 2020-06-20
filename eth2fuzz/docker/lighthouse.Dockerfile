FROM ubuntu:18.04 AS build

ARG RUST_TOOLCHAIN="nightly"
ARG GIT_BRANCH="master"

ENV CARGO_HOME=/usr/local/rust
ENV RUSTUP_HOME=/usr/local/rust
ENV PATH="$PATH:$CARGO_HOME/bin"

# Update ubuntu
# Install dependencies
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		build-essential \
		pkg-config \
		libssl-dev \
		ca-certificates \
		curl \
		git

# Install Rust and Cargo
RUN curl --proto '=https' \
	--tlsv1.2 \
	-sSf https://sh.rustup.rs | sh -s -- -y \
	--default-toolchain "$RUST_TOOLCHAIN"

# Clone lighthouse
RUN git clone \
	--branch "$GIT_BRANCH" \
	--recursive \
	--depth 1 \
	https://github.com/sigp/lighthouse

#####################################
############ FUZZERS ################

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
	build-essential \
	libtool-bin \
	python3-dev \
	automake \
	flex \
	bison \
	libglib2.0-dev \
	libpixman-1-dev \
	clang \
	python3-setuptools \
	llvm \
	binutils-dev \
	libunwind-dev \
	libblocksruntime-dev

# Install Rust fuzzer
RUN cargo install honggfuzz
RUN cargo install cargo-fuzz
RUN cargo install afl

#####################################
############ eth2fuzz ################

WORKDIR /eth2fuzz

# Copy all
COPY . .

# Build the CLI tool
RUN make build

ENTRYPOINT ["/eth2fuzz/eth2fuzz"]
