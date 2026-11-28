FROM rust:1.100.0-slim-trixie AS rust

FROM base

# Native libraries most -sys crates (openssl-sys, etc.) look for.
USER root
RUN apt-get update && apt-get install -y pkg-config libssl-dev --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*
# Login shells reset PATH from /etc/profile, which drops the ENV PATH below.
RUN echo 'export PATH="/usr/local/cargo/bin:$PATH"' > /etc/profile.d/rust.sh
USER vscode

# Install Rust. rustup and cargo homes are owned by vscode so rust-toolchain.toml files can
# install other toolchains and `cargo install` works without sudo.
ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:$PATH
COPY --from=rust --chown=vscode:vscode /usr/local/rustup /usr/local/rustup
COPY --from=rust --chown=vscode:vscode /usr/local/cargo /usr/local/cargo
RUN rustup component add rustfmt clippy rust-analyzer rust-src && \
    mkdir -p /usr/local/cargo/registry

# Install cargo-binstall (prebuilt binaries instead of compiling from source)
ARG TARGETARCH
# renovate: datasource=github-releases depName=cargo-bins/cargo-binstall
ARG CARGO_BINSTALL_VERSION=v1.29.0
RUN ARCH=$([ "${TARGETARCH}" = "amd64" ] && echo "x86_64" || echo "aarch64") && \
    curl -fsSL "https://github.com/cargo-bins/cargo-binstall/releases/download/${CARGO_BINSTALL_VERSION}/cargo-binstall-${ARCH}-unknown-linux-musl.tgz" \
    | tar -xz -C /usr/local/cargo/bin cargo-binstall

# Install cargo tools
# renovate: datasource=crate depName=cargo-nextest
ARG CARGO_NEXTEST_VERSION=0.9.152
# renovate: datasource=crate depName=cargo-deny
ARG CARGO_DENY_VERSION=0.22.2
RUN cargo binstall --no-confirm --disable-telemetry \
        "cargo-nextest@${CARGO_NEXTEST_VERSION}" \
        "cargo-deny@${CARGO_DENY_VERSION}" && \
    rm -rf /usr/local/cargo/registry/* /usr/local/cargo/git
