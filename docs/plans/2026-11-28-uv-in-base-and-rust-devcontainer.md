# Plan: uv in base, and a Rust devcontainer

- **Status:** Implemented (2026-11-28)
- **Date:** 2026-11-28
- **Repos:** `devcontainers`

## Goal

1. Put `uv`, Python 3.14 (the default) and Python 3.15 in `base`, so Python works in every image.
2. Add a `rust` image and a gantry base (`devcontainer_configs/bases/rust`) with sane VS Code defaults.

Decisions are recorded in [ADR 0003](../adrs/0003-uv-in-base-and-rust-image.md).

## Steps

### 1. uv in base

- `dockerfiles/base/Dockerfile`: copy `uv` / `uvx` from `ghcr.io/astral-sh/uv:0.13.10-debian`, set `UV_CACHE_DIR` / `UV_LINK_MODE`, run `uv python install 3.15` then `uv python install --default 3.14`.
- `dockerfiles/python/Dockerfile`: drop the uv install and keep `uv python install --default ${PYTHON_VERSION}` (3.14), so the tag still matches `python`.

### 2. Rust image

- `dockerfiles/rust/Dockerfile`: copy `/usr/local/{rustup,cargo}` from `rust:1.100.0-slim-trixie`, owned by `vscode`. Add `rustfmt clippy rust-analyzer rust-src`, `pkg-config libssl-dev`, cargo-binstall, cargo-nextest and cargo-deny (each pinned with a `# renovate:` annotation). Add `/etc/profile.d/rust.sh` so login shells keep cargo on PATH.
- `docker-bake.hcl`: a `rust` target on `base`, tagged `rust:main` and `rust:1`.

### 3. Gantry base

`devcontainer_configs/bases/rust/devcontainer.json`: the standard mounts, plus a shared `devcontainer-cargo-registry` volume. Extensions: rust-analyzer, CodeLLDB, Even Better TOML, Dependi, plus the common set. Settings: rustfmt on save, clippy check over all targets, a separate rust-analyzer target dir.

## Verification (done locally, amd64)

- `base`, `rust` and `python:3.14`: `python` / `python3` → 3.14.10, and `python3.15` → 3.15.2.
- `rust:1`: cargo/rustc 1.100.0, nextest, deny and binstall run. `cargo new && cargo clippy && cargo run` works. A login shell keeps cargo on PATH. A fresh named volume on `/usr/local/cargo/registry` is owned by `vscode` and writable.
- `gantry build --repo <local clone> --files devcontainer_configs/bases/rust/devcontainer.json --files devcontainer_configs/features/prek.libsonnet` produces the expected config.

## Follow-ups

- After merge and the first push: make the new `ghcr.io/ivanklee86/devcontainer/rust` package public, and give this repo's Actions `Write` access (README steps 3–4).
- Optional: move `devops` from `python` onto `base` now that base has uv and 3.14. Nothing would change for it.
