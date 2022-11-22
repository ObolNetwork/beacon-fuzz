FROM ubuntu:18.04 AS build

ARG RUST_TOOLCHAIN="nightly"
ENV CARGO_HOME=/usr/local/rust
ENV RUSTUP_HOME=/usr/local/rust
ENV PATH="$PATH:$CARGO_HOME/bin"

# Update ubuntu
# Install dependencies
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		build-essential \
		ca-certificates \
		curl \
		git

# Install Rust and Cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain "$RUST_TOOLCHAIN"

WORKDIR /eth2fuzz

# Copy all
COPY . .

# Build the CLI tool
RUN make -f eth2fuzz.mk build

#####################################
############ charon #################

FROM ubuntu:18.04

ARG GIT_BRANCH="main"
ARG CHARON_VERSION="v0.11.0"

# Update ubuntu
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		software-properties-common \
		curl \
		git \
		clang

# Install golang
RUN add-apt-repository ppa:longsleep/golang-backports
RUN apt-get update && \
	apt-get install -y \
	golang

WORKDIR /eth2fuzz

ENV GOPATH="/eth2fuzz"

# Install charon
RUN mkdir -p /eth2fuzz/src/github.com/ObolNetwork/
RUN cd /eth2fuzz/src/github.com/ObolNetwork/ && \
    git clone --branch "$GIT_BRANCH" \
    --recurse-submodules \
    https://github.com/ObolNetwork/charon

# Build charon
RUN cd /eth2fuzz/src/github.com/ObolNetwork/charon/ && go install .

#####################################
############ eth2fuzz ###############

# COPY --from=build shared .
COPY --from=build /eth2fuzz/eth2fuzz .

# Set env for eth2fuzz target listing
ENV CURRENT_CLIENT="CHARON"

ENTRYPOINT ["/eth2fuzz/eth2fuzz"]
