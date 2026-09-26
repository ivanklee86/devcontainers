---
status: accepted
date: 2026-09-26
---

# Pin the python base to `python:3.14` and mount `~/.claude` in every base

## Context and Problem Statement

The python base pointed at the mutable `python:main` tag, which conflicts with the "versions should always be pinned" rule, while go already uses `go:<version>` tags. Only the terraform base mounted the host's `~/.claude`, so Claude Code settings and history behaved differently depending on the base.

## Considered Options

* Pinning: publish and use `python:3.14` / keep `python:main` and document it as an exception.
* `~/.claude`: mount in every base / remove from terraform / opt-in `features/*.libsonnet`.

## Decision Outcome

Chosen: **publish `python:3.14` (alongside `:main`) and point the python base at it**, and **mount `~/.claude` in every base by default**.

### Consequences

* Good, because the python base pins the Python version the same way go does, and a new Python version becomes a new bake target instead of a silent change.
* Good, because Claude Code settings, memory and history follow the user into every devcontainer.
* Bad, because `python:3.14` is still a moving tag (tool updates land under it); it is not a digest pin.
* Bad, because `~/.claude` must exist on the host or the container fails to start (Codespaces won't have it). If that becomes a use case, move the mount into an opt-in feature.
* Bad, because the mount hides the image's baked `~/.claude/settings.json` (the ccusage statusline); it only applies when nothing is mounted.
