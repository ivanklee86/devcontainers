# Plan: share the host's gh login with every devcontainer

- **Status:** Approved; all decisions made (2026-11-26)
- **Date:** 2026-11-26
- **Repos:** `devcontainers`, plus a regenerate in every gantry consumer: `tangle`, `tangle-deployments`, `gantry`, `argonap`, `rubrical`, `homeops`, `terraform-modules`

## Goal

Make `gh` (and git over HTTPS) work in every gantry-generated devcontainer without a separate `gh auth login` in each one. Today only homeops has it, through a per-repo override. Move it into the shared bases so each repo gets it by regenerating.

## Current state

- **The host's gh login** is in `~/.config/gh/hosts.yml` as a plaintext `oauth_token`: there is no keyring on WSL. The file is `0600`, owned by uid 1000, which matches the container's `vscode` user.
- **Git depends on gh.** The host `~/.gitconfig`, which every base mounts, sets `credential.https://github.com.helper = !gh auth git-credential` (same for `gist.github.com`). Every image ships `gh` (`dockerfiles/base/Dockerfile`), so inside a container without gh auth, **`git push` over HTTPS fails as well**, not just `gh`. That's the tangle symptom.
- **homeops** adds the mount in `.devcontainer/homeops.libsonnet`:

  ```jsonnet
  "source=${localEnv:HOME}/.config/gh,target=/home/vscode/.config/gh,type=bind,consistency=cached",
  ```

  No `gh auth setup-git` or post-install step is needed, because the mounted `.gitconfig` already points git at gh.
- **The bases** (`bases/{go,python,terraform}/devcontainer.json`) mount `.gitconfig`, `.claude` and `.ssh/known_hosts`. terraform also mounts `.aws` and `.kube`. None of them mounts `.config/gh`.

Generated mounts per consumer:

| Repo | Base | Generated mounts today | Notes |
| --- | --- | --- | --- |
| tangle | go | `.gitconfig` only | **Stale**: generated before the bases added `.claude` and `known_hosts` |
| gantry | go | `.gitconfig .claude .ssh/known_hosts` | |
| argonap | go | `.gitconfig .claude .ssh/known_hosts` | |
| rubrical | python | `.gitconfig .claude .ssh/known_hosts` | |
| homeops | terraform | `+ .aws .config/gh`, `.kube` filtered out | Per-repo gh override |
| tangle-deployments | terraform | `.gitconfig .aws .kube .claude .ssh/known_hosts` | |
| terraform-modules | terraform | `.gitconfig .aws .kube .claude .ssh/known_hosts` | No `local_build` |
| devcontainers (itself) | hand-written | `.gitconfig` only | Not gantry-generated; out of scope unless wanted |

## Options

| Option | How | For | Against |
| --- | --- | --- | --- |
| **A. Bind-mount `~/.config/gh` in every base** (recommended) | One line in each base, same as homeops | Proven in homeops. Covers `gh` and git together. `gh auth refresh` and scope changes on the host show up everywhere | Every container, and anything that runs in it (npm/go postinstall scripts, agents), can read the full host token |
| B. Same mount, `readonly` | Add `,readonly` | Containers can't overwrite the host login or config | `gh auth login/refresh/switch` and `gh config set` fail inside the container. Refresh on the host instead |
| C. `remoteEnv: { GH_TOKEN: "${localEnv:GH_TOKEN}" }` | Env var from the host | No file mount. Can carry a narrower fine-grained PAT | The host has to export `GH_TOKEN` to the process that starts VS Code. It's empty when launched from a GUI. A second token to manage |
| D. Opt-in feature `features/gh_config.libsonnet` | Repos add it to `gantry.yaml` | The token is only exposed where you choose | "Globally" becomes "per repo again", which is what's broken now |

Recommendation: **A**, mounted **read-write** to match homeops, so `gh auth refresh -s <scope>` works from inside. Switch to B if you'd rather keep the host login immutable from containers. That's a one-word change in each base.

## Steps

### 1. `devcontainers`: bases, docs, ADR

1. Add the mount to `bases/go`, `bases/python` and `bases/terraform` `devcontainer.json`, after `known_hosts`. Use a comment in the bases' style:

   ```jsonc
   // Mount the host gh config so gh, and git through the host .gitconfig's `gh auth git-credential`
   // helper, use the host's GitHub login. hosts.yml holds the token in plaintext; the host directory must exist.
   "source=${localEnv:HOME}/.config/gh,target=/home/vscode/.config/gh,type=bind,consistency=cached"
   ```

2. `docs/architecture.md`: add `~/.config/gh` to "Every base bind-mounts …". **The host needs `gh auth login` done once**, or at least an existing `~/.config/gh`, or the container won't start, the same rule as `~/.claude`.
3. `docs/adrs/0002-share-host-gh-config.md` (MADR 4.0.0): record options A–D and the token-exposure trade-off.
4. PR, then merge (with your approval). Consumers pick it up from `ref: main` on their next regenerate.

### 2. Regenerate each consumer: one PR per repo

In each repo: `gantry build --config gantry.yaml --write` in `.devcontainer/` (homeops: `task devcontainer:…`), then rebuild the container and verify.

- **homeops**: drop its own `.config/gh` line from `homeops.libsonnet`. Otherwise the generated file has the mount twice, and Docker refuses duplicate targets. Keep the `.kube` filter. Update the comment.
- **tangle**: the regenerate also brings in the `.claude` and `known_hosts` mounts it's missing. That's a behavior change worth calling out in the PR: the host `~/.claude` hides the image's baked settings.
- **gantry, argonap, rubrical, tangle-deployments, terraform-modules**: regenerate. The diff should be only the new mount.
- **devcontainers' own `.devcontainer/`**: leave it hand-written unless you want it too.

Verify in each rebuilt container:

- `gh auth status` shows the host account.
- `git ls-remote https://github.com/ivanklee86/<private repo>` succeeds, which shows the credential helper works.
- `ls -l ~/.config/gh/hosts.yml` is owned by `vscode`.

### 3. Optional hardening (separate decision)

- **Narrower token:** give containers a fine-grained PAT, either via option C or a separate `GH_CONFIG_DIR` on the host with its own login, instead of the host's full `gho_` OAuth token.
- **Make git independent of gh:** add a host `~/.gitconfig` fallback such as `credential.helper = cache`. Then git keeps working even if gh auth is missing.

## Risks

- **The host path must exist.** If `~/.config/gh` is missing, the container fails to start. On a new machine, run `gh auth login` before opening any devcontainer. Document it next to the `~/.claude` rule.
- **Token exposure widens** from one container (homeops) to all of them. Accept it (A), limit writes (B), or narrow the token (step 3).
- **Codespaces or other hosts:** `${localEnv:HOME}/.config/gh` doesn't exist there. Not a current use.

## Decisions (2026-11-26)

1. **Mount mode:** read-write (option A), matching homeops, so `gh auth refresh` works inside containers.
2. **The devcontainers repo's own `.devcontainer`:** left out. It stays hand-written with only `.gitconfig`.
3. **Hardening (step 3):** neither for now. Ship the mount only and revisit later.
