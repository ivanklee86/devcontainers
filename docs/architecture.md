# Architecture

## Build graph

```mermaid
graph TD
    base --> python
    base --> go_125
    base --> go_126
    base --> go_127
    python --> devops
```

## Shared tools (`base`)

All images inherit these from `dockerfiles/base/Dockerfile`:

- [build-essential](https://packages.debian.org/stable/build-essential), [binutils-gold](https://packages.debian.org/stable/binutils-gold), [git-lfs](https://git-lfs.com/)
- [GitHub CLI](https://cli.github.com/) (`gh`)
- [prek](https://github.com/j178/prek)
- [Taskfile](https://taskfile.dev/) (`task`)
- [Claude Code CLI](https://claude.com/claude-code)
- [CodeRabbit CLI](https://www.coderabbit.ai/cli)
- [Gantry](https://github.com/ivanklee86/gantry)
- [1Password CLI](https://developer.1password.com/docs/cli/) (`op`)
- [bun](https://bun.sh/)
- [ccusage](https://github.com/ryoppippi/ccusage)

## Tools per image

### `python` (`dockerfiles/python/Dockerfile`)
- [uv / uvx](https://docs.astral.sh/uv/)
- [Python](https://www.python.org/) (via `uv python install`)

### `go_125` / `go_126` / `go_127` (`dockerfiles/go/Dockerfile`)
- [Go toolchain](https://go.dev/) (version set via `GO_VERSION` build arg: 1.25, 1.26, or 1.27)
- [golangci-lint](https://golangci-lint.run/)
- [go-junit-report](https://github.com/jstemmer/go-junit-report)
- [gomplate](https://docs.gomplate.ca/)
- [goreleaser](https://goreleaser.com/)

### `devops` (`dockerfiles/devops/Dockerfile`, built on top of `python`)
- [tenv](https://github.com/tofuutils/tenv)
- [go-jsonnet](https://github.com/google/go-jsonnet)
- [AWS CLI](https://aws.amazon.com/cli/)
- [terraform-docs](https://terraform-docs.io/)
- [tflint](https://github.com/terraform-linters/tflint)
- [kubectl](https://kubernetes.io/docs/reference/kubectl/)
- [helm](https://helm.sh/)
- [tanka](https://tanka.dev/) (`tk`, `jb`)
- [k9s](https://k9scli.io/)

## Consuming a base (`devcontainer_configs/`)

Repos don't hand-write `devcontainer.json`. They generate it with [Gantry](https://github.com/ivanklee86/gantry) from a base config in `devcontainer_configs/bases/<lang>` and optional `devcontainer_configs/features/*.libsonnet`, plus a repo-specific libsonnet overlay:

```
.devcontainer/
  gantry.yaml             # overlays: base + features, then <repo>.libsonnet
  <repo>.libsonnet        # name, extra extensions, post-install hook
  devcontainer.json       # GENERATED: gantry build --config gantry.yaml --write
  devcontainer-lock.json
  post_install.sh         # repo setup + git config
  Dockerfile              # only if the repo needs extra tools; add features/local_build.libsonnet
```

| Base | Image |
|---|---|
| `python` | `ghcr.io/ivanklee86/devcontainer/python:3.14` |
| `go` | `ghcr.io/ivanklee86/devcontainer/go:1.26` |
| `terraform` | `ghcr.io/ivanklee86/devcontainer/devops:main` |

| Feature | Effect |
|---|---|
| `prek.libsonnet` | Runs `prek install && prek run` after create. |
| `local_build.libsonnet` | Swaps `image` for a build of `.devcontainer/Dockerfile`. |
| `precommit.libsonnet` | Legacy: installs pre-commit with uv. Prefer `prek.libsonnet`. |

Rules:

- Never edit the generated `devcontainer.json` by hand. Change the libsonnet overlay (or the base here) and regenerate.
- `postCreateCommand` entries run in parallel, so don't rely on order between them.
- Every base bind-mounts `~/.gitconfig`, `~/.claude` and `~/.ssh/known_hosts` from the host. **These paths have to exist on the host** or the container won't start. The `~/.claude` mount hides the image's baked `~/.claude/settings.json` (the ccusage statusline); copy its `statusLine` block into the host's settings if you want it.
- Renovate updates the base configs here through the `devcontainer` manager (see `renovate.json`).
