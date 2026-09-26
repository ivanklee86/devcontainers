# Plan: upgrade the Python devcontainer base and move rubrical onto it

- **Status:** Approved; all decisions made (2026-09-26)
- **Date:** 2026-09-26
- **Replaces:** `rubrical/devcontainer-upgrade.scratchpad.md` (2026-09-24)
- **Repos:** `devcontainers`, `rubrical`

## Goal

Bring `devcontainer_configs/bases/python` up to the level of the go and terraform bases. Then replace
rubrical's hand-written devcontainer with the gantry-generated layout that `tangle` and
`tangle-deployments` already use.

## Out of scope (deferred uv cleanup)

rubrical already builds, tests and publishes with uv. The items below are uv or packaging cleanup
rather than devcontainer work, so they're left for the later uv pass:

- `actions/setup-python` with `cache: 'pip'` running next to `setup-uv` in `ci.yaml` and `release.yaml`.
- The leftover `pip install -U pip poetry` in `release-docs.yaml`.
- `isort` and `pip` in the `dev` group: ruff `I` already sorts imports, and `docs:gen` could use `uvx typer`.
- The duplicate `.vscode/settings.json`.
- Bumping the `uv-pre-commit` rev. It works with the image's uv 0.12.17 as it is.

`pre-commit` → `prek` **is in scope**, because the shared base's `postCreateCommand` depends on it.

## Target layout (the tangle pattern)

```
.devcontainer/
  gantry.yaml             # base + prek feature (+ local_build only if there's a Dockerfile) + <repo>.libsonnet
  <repo>.libsonnet        # name, extra extensions, post-install hook
  devcontainer.json       # GENERATED: gantry build --config gantry.yaml --write
  devcontainer-lock.json
  post_install.sh
```

---

## Phase 1: `devcontainers` (do this first)

rubrical's `gantry.yaml` reads the bases from `ref: main`, so these changes have to be merged, and
the image pushed, before Phase 2 is regenerated.

### 1a. Bring `bases/python/devcontainer.json` up to the other bases

| Gap | Change |
|---|---|
| `"name": "devcontainer"` | Keep it as a placeholder, since every consumer overrides it. Optionally rename it to `"python"` to match go's `"fullstack"` pattern. |
| Missing `anthropic.claude-code` and `GitHub.copilot` | Add both. rubrical has them today, so leaving them out would be a regression. |
| Missing `known_hosts` read-only mount | Add it, copied from terraform. It's harmless and stops TOFU prompts during non-interactive git. |
| `~/.claude` mount (terraform only) | Add it to python **and go**, so every base mounts it by default (D2). See 1e for the baked settings file it hides. |
| `docker-in-docker:2` | Bump to `:4` in **all three** bases. tangle already has `:4` in its generated file (Renovate edited it there), so the next `gantry build` in tangle would quietly downgrade it. |
| `remote.sshAgentForwarding` (python only) | Leave it. It's a user setting, so it has no effect in the container, but it does no harm. Optionally remove it. |

### 1b. Fixes that apply to all bases

- **Taskfile schema glob:** change `**/Taskfile.yml` to `**/Taskfile.{yml,yaml}`. Every repo uses `Taskfile.yaml`, so the schema is never applied right now.
- **`github.vscode-github-actions`:** move it into the bases. tangle, tangle-deployments and rubrical all add it, so the three libsonnets can then drop it. They **must** drop it: gantry concatenates extension lists without deduplicating, so keeping it gives a duplicate entry.

### 1c. Stop the bases from drifting behind Renovate (root cause)

Renovate's `devcontainer` manager only matches `.devcontainer/devcontainer.json` and
`.devcontainer.json` by default. As a result:

- In `devcontainers`, the bases (`devcontainer_configs/bases/*/devcontainer.json`) are **never
  updated**. This is why they still say `docker-in-docker:2`.
- In consumer repos, Renovate updates the **generated** file, and gantry undoes that on the next regeneration.

Fix: in `devcontainers/renovate.json`, extend the manager's `managerFilePatterns` to include
`/^devcontainer_configs\/bases\/.+\/devcontainer\.json$/`. The base images
(`python:main`, `devops:main`) are our own mutable tags. Renovate can't bump them anyway, so the
docker-in-docker feature is the dependency that matters here.

Consumer repos can keep automerging Renovate's edits to the generated file. The optional drift check
(Phase 2e) is what catches base changes that haven't been pulled in.

### 1d. Pin the python image to `python:3.14` (D3)

`CLAUDE.md` says "versions should always be pinned", but the python base points at `python:main`.
- In `docker-bake.hcl`, add `${DOCKER_REPO_URL}/python:3.14` to the `python` target's `tags`. Keep
  `:main`, because the `devops` target builds on top of python and other consumers may still use `:main`.
- Point `bases/python/devcontainer.json` at `ghcr.io/ivanklee86/devcontainer/python:3.14`.
- Keep the tag and `PYTHON_VERSION=3.14` in `dockerfiles/python/Dockerfile` in step. When Python 3.15
  lands, add a `python_315` target the same way go has `go_126`/`go_127`.

This pins the Python version, the same guarantee go has. It is still not an immutable digest.

### 1e. Mount `~/.claude` by default (D2)

- Add the mount from terraform to the python and go bases:
  `source=${localEnv:HOME}/.claude,target=/home/vscode/.claude,type=bind,consistency=cached`.
- **Side effect:** the mount hides the image's baked `/home/vscode/.claude/settings.json` (the
  ccusage statusline from `dockerfiles/base/claude-settings.json`). If you want the statusline,
  move that `statusLine` block into the host's `~/.claude/settings.json`. The baked file stays
  useful only when nothing is mounted (for example `task bake:run:*`), so keep it.
- **Host requirement:** Docker won't start a container when the bind-mount source is missing. Every
  host has to have `~/.claude`. Codespaces won't have it; nobody uses Codespaces right now, but
  `post_install.sh` has a Codespaces branch. If that changes, move the mount into an opt-in feature.
- Note the host requirement in the consumer docs (1f).

### 1f. Document the consumer side

Add a short "Consuming a base" section to `docs/architecture.md`, or a new `docs/consuming.md`. It
should cover the target layout above, the `gantry build` command, when to use `local_build`, and
the rule that the generated file must not be edited by hand.

### Not changing in this phase

- **The duplicated `post_install.sh` git block** (gpg + `autoSetupRemote`). This is a good candidate
  for a `features/git.libsonnet` or the base image, but it's a separate change that touches every
  consumer. rubrical keeps its copy for now.
- **`postCreateCommand` object entries run in parallel.** See Risks.

### Verify (devcontainers)

- `task bake:build:python`, then `task bake:run:python`, and check `uv --version`,
  `python3 --version` (3.14.x), `prek --version` and `gantry --version`.
- The CI `build` job passes and pushes both `python:main` and `python:3.14`. Also make sure
  `ghcr.io/ivanklee86/devcontainer/python:3.14` pulls without logging in, because the package is public.
- Regenerate tangle's `devcontainer.json` in a scratch checkout. The only differences should be the
  intended ones: the schema glob, the GitHub Actions extension and the `~/.claude` and `known_hosts`
  mounts. ✅ Done 2026-09-26 against the local branch. The extension appears twice until tangle's
  libsonnet drops it.

---

## Phase 2: `rubrical`

### 2a. Devcontainer

- **Delete** `.devcontainer/Dockerfile`. `python:main` already provides everything it installs
  (uv, Python 3.14, task), plus prek, gh and claude. With no Dockerfile, the base `image` is used
  directly and `local_build.libsonnet` is left out (D1).
- **Add** `.devcontainer/gantry.yaml`:
  ```yaml
  version: 1
  output_path: devcontainer.json
  overlays:
    - repo: https://github.com/ivanklee86/devcontainers
      ref: main
      files:
        - devcontainer_configs/bases/python/devcontainer.json
        - devcontainer_configs/features/prek.libsonnet
    - repo: ..
      subdirectory: .devcontainer
      files:
        - rubrical.libsonnet
  ```
- **Add** `.devcontainer/rubrical.libsonnet`:
  ```jsonnet
  {
    name: "rubrical",
    postCreateCommand+: {
      "rubrical-post-install": "bash ./.devcontainer/post_install.sh",
    },
  }
  ```
  (After 1b, nothing needs adding to `extensions`.)
- **Regenerate** with `cd .devcontainer && gantry build --config gantry.yaml --write`. This also
  removes the dead black/flake8/pylint/mypy settings and `dockerDashComposeVersion`. On the first
  container build, commit the `devcontainer-lock.json` it creates.
- **Edit** `post_install.sh`: keep `uv sync --group dev` and delete `uv run pre-commit install`,
  since the prek feature now does it. Keep the git config block.

### 2b. Hooks: pre-commit to prek

- `.pre-commit-config.yaml` runs under prek unchanged. Bump ruff-pre-commit from `v0.14.11` to the
  current release so it matches the ruff in `uv.lock`, which prevents fights between the hook and
  `task python:fmt`. Add `renovatebot/pre-commit-hooks` → `renovate-config-validator` to match tangle.
- Remove `pre-commit` from the `dev` group, then run `uv lock`.

### 2c. CI

- Add a `pre-commit` job to `.github/workflows/ci.yaml` using
  `j178/prek-action@4e14d07f9231acabce116ccfca13b13dd9755ece # v3.0.0` with `prek-version: 0.5.3`,
  copied from tangle.
- **Manual:** turn off the pre-commit.ci GitHub app for rubrical once the job is green.

### 2d. Renovate

- Delete the dead `poetry` package rule.
- Add the `devcontainer` group (`matchManagers: ["devcontainer"]`, automerge) from tangle-deployments.

### 2e. Taskfile

- Add `tasks/devcontainer.yaml` (or a top-level task) with `gen`: `dir: .devcontainer`,
  `gantry build --config gantry.yaml --write`.
- *Optional:* add a CI job that runs `ghcr.io/ivanklee86/gantry:0.0.4` to regenerate the file and
  fails if `git diff --exit-code .devcontainer/` isn't empty. This catches hand edits and bases
  that haven't been pulled in. If it's worth doing, roll it out to the tangle repos too.

### Verify (rubrical)

1. "Rebuild Container" in VS Code. Confirm that `install-prek` and `rubrical-post-install` both succeed.
   In the container, `claude` should see the host's settings and history through the `~/.claude` mount.
2. `task` (install, lint, test), `task docs:test`, `task docker:build` (checks docker-in-docker), and `prek run --all-files`.
3. Claude Code and Copilot extensions are present. The Taskfile schema is active in `Taskfile.yaml`.
4. A PR's CI shows the new `pre-commit` job. pre-commit.ci no longer reports.

---

## Decisions

- **D1: rubrical Dockerfile.** ✅ *Decided 2026-09-26:* none. rubrical uses the base `image` directly, with no `local_build`. Add a Dockerfile later only if rubrical needs extra tools. See 2a.
- **D2: `~/.claude` host mount.** ✅ *Decided 2026-09-26:* mounted by default in every base. See 1e.
- **D3: python image pinning.** ✅ *Decided 2026-09-26:* use `python:3.14`. See 1d.
- **D4: scope of 1b and 1c.** ✅ *Decided 2026-09-26:* all three bases (python, go, terraform) in the Phase 1 PR. tangle and tangle-deployments pick the changes up the next time they're regenerated (Rollout step 4).

## Risks

- **Parallel `postCreateCommand`.** `install-prek` runs `prek run`, which includes the `uv-lock` hook,
  while `rubrical-post-install` runs `uv sync` at the same time. uv takes its own locks, so this
  should be safe, but look for errors in the first rebuild log. If it's flaky, have `post_install.sh`
  run `prek install` itself and leave out `prek.libsonnet`.
- **`ref: main` in `gantry.yaml`.** The output can change between two runs of the same generation
  command. That's acceptable here because the generated file is committed and reviewed.
- **Ordering.** If Phase 2 is regenerated before Phase 1 merges, it picks up the old python base
  (no Claude/Copilot, `:2` docker-in-docker). It would also fail outright, because `python:3.14` doesn't exist until the Phase 1 image push.

## Rollout

1. PR in `devcontainers`: Phase 1. Merge it and wait for the image push.
2. PR in `rubrical`: Phase 2a–2e. Rebuild and verify.
3. Turn off pre-commit.ci for rubrical.
4. Follow-up: in tangle and tangle-deployments, remove `github.vscode-github-actions` from the libsonnet, then regenerate to pick up 1b/1c and the new mounts. Delete the rubrical scratchpad.
