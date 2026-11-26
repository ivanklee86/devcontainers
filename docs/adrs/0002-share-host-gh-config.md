---
status: accepted
date: 2026-11-26
---

# Mount the host's `~/.config/gh` read-write in every base

## Context and Problem Statement

The host `~/.gitconfig`, which every base mounts, sends GitHub credentials through `gh auth git-credential`. Every image ships `gh`, but only homeops mounted the host's gh config, through its own overlay. In every other devcontainer, `gh` had no login and git over HTTPS failed with it. How should devcontainers get a GitHub login?

## Considered Options

* Bind-mount `~/.config/gh` read-write in every base (what homeops did).
* The same mount, `readonly`.
* `remoteEnv` `GH_TOKEN` from a host environment variable.
* An opt-in `features/gh_config.libsonnet`.

## Decision Outcome

Chosen: **bind-mount `~/.config/gh` read-write in every base**. It's proven in homeops, covers `gh` and git together, and lets `gh auth refresh` work from inside a container.

### Consequences

* Good, because `gh` and git over HTTPS work in every generated devcontainer without a per-container login.
* Good, because a login or scope change on the host shows up in every container.
* Bad, because every container, and anything that runs in it, can read the host's full GitHub token, which is plaintext in `hosts.yml` on WSL. Narrowing it (a separate fine-grained PAT, or a separate `GH_CONFIG_DIR`) is deferred.
* Bad, because a container can overwrite the host login (`gh auth login/switch`, `gh config set`). `readonly` would prevent that, but it would also break `gh auth refresh` inside containers.
* Bad, because `~/.config/gh` must exist on the host or the container fails to start, the same as `~/.claude` (ADR 0001).
* Neutral: repos that added the mount themselves (homeops) have to drop their own line, because Docker rejects two mounts with the same target.
