---
status: accepted
date: 2026-11-28
---

# Ship uv, Python 3.14 and 3.15 in `base`, and add a `rust` image tagged `rust:1`

## Context and Problem Statement

Claude Code reaches for Python scripts all the time, but only the `python` and `devops` images had `uv` or a Python of their own. In the go images, those scripts failed or fell back to whatever Python happened to be installed. Separately, there was no image or base for Rust work. Two questions:

1. Where should uv and a default Python live?
2. How should the Rust image be built, tagged and pinned?

## Considered Options

* uv and Python: in `base` with 3.14 (default) and 3.15 / in `base` with only 3.15 as the default / in `base` with no Python (uv fetches one on demand) / keep them in `python` only.
* Rust toolchain: copy it from the official `rust` image / install with `rustup-init` and a pinned `RUST_VERSION` ARG.
* Rust tag: `rust:1` + `rust:main` / `rust:1.<minor>` per version, like go / `rust:main` only.

## Decision Outcome

Chosen:

* **uv, Python 3.14 and Python 3.15 in `base`, with 3.14 as the default** `python` / `python3` (`uv python install --default`). 3.15 is there as `python3.15` and for `uv run --python 3.15`, but 3.14 stays the default because third-party wheels lag a new release. The `python` image still sets its tagged version (3.14) as the default, so `python:3.14` stays true if base's default moves.
* **Copy the toolchain from `rust:<version>-slim-trixie`**, the same pattern as go. Renovate's dockerfile manager bumps the `FROM` tag with no custom rule.
* **Tag `rust:1` and `rust:main`.** The base config points at `rust:1`. Projects that need an exact toolchain pin it in `rust-toolchain.toml`, and rustup installs it on first use.

### Consequences

* Good, because Python scripts work in every devcontainer on a version with broad wheel support, and 3.15 is ready without a download.
* Good, because Rust releases every six weeks and stays backwards compatible within 1.x. One image that tracks the latest stable, plus `rust-toolchain.toml` for exact pins, avoids a bake target per release.
* Bad, because every image grows by one uv binary and two Python installs (~200 MB).
* Bad, because `rust:1` is a moving tag, like `python:3.14` (ADR 0001). It is pinned in the sense that the toolchain version is pinned in the Dockerfile, not at the consumer.
* Bad, because `uv python install --default` is a uv preview feature (`--preview-features python-install-default`). If uv changes it, the base build breaks loudly. It won't drift silently.
