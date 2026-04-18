# pin-dependencies

Detect unpinned dependencies across Dockerfiles, GitHub Actions workflows, and build scripts in this repo, resolve their latest stable versions, pin them in-place, and update `renovate.json` so Renovate keeps them current.

---

## Phase 1: Detect

Search for unpinned dependencies across the repo. For each match, note the file path and line number.

**Dockerfiles** — search all files matching `**/Dockerfile*`:
- `FROM .*:latest` — unpinned base images
- `COPY --from=.*:latest` — unpinned multi-stage sources
- `releases/latest/download` — GitHub release script installers using `latest`
- `go install .*@latest` — unpinned Go module installs
- `taskfile\.dev/install\.sh` without a `-v vX.Y.Z` flag

**GitHub Actions** — search `.github/workflows/*.yaml`:
- `uses: [^@]+@v\d+$` — actions pinned to a major version only (e.g. `@v4`, not `@v4.1.0`)

Do NOT flag:
- `claude.ai/install.sh` — no public versioned endpoint; note it to the user as a manual item
- `mcr.microsoft.com/devcontainers/base:${BASE}` — `${BASE}` is a distro name, not a version; Renovate handles it
- `golang:${GO_VERSION}` — version comes from `docker-bake.hcl` args; Renovate handles it

---

## Phase 2: Resolve Versions

For each detected dependency, fetch the latest stable version using WebFetch. Use these exact endpoints:

| Dependency | API Endpoint | Extract |
|---|---|---|
| `golangci/golangci-lint` | `https://api.github.com/repos/golangci/golangci-lint/releases/latest` | `.tag_name` |
| `gomplate/gomplate` | `https://api.github.com/repos/hairyhenderson/gomplate/releases/latest` | `.tag_name` |
| `goreleaser/goreleaser` | `https://api.github.com/repos/goreleaser/goreleaser/releases/latest` | `.tag_name` |
| `ghcr.io/astral-sh/uv` | `https://api.github.com/repos/astral-sh/uv/releases/latest` | `.tag_name` |
| `j178/prek` (script installer) | `https://api.github.com/repos/j178/prek/releases/latest` | `.tag_name` |
| taskfile (`go-task/task`) | `https://api.github.com/repos/go-task/task/releases/latest` | `.tag_name` |
| `github.com/jstemmer/go-junit-report/v2` | `https://proxy.golang.org/github.com/jstemmer/go-junit-report/v2/@latest` | `.Version` |
| `actions/checkout` | `https://api.github.com/repos/actions/checkout/releases/latest` | `.tag_name` |
| `docker/setup-buildx-action` | `https://api.github.com/repos/docker/setup-buildx-action/releases/latest` | `.tag_name` |
| `docker/login-action` | `https://api.github.com/repos/docker/login-action/releases/latest` | `.tag_name` |
| `arduino/setup-task` | `https://api.github.com/repos/arduino/setup-task/releases/latest` | `.tag_name` |

If a version can't be resolved (API error, rate limit, no releases), note it as unresolved and skip that dep.

---

## Phase 3: Present & Confirm

Display a table of proposed changes:

```
| File | Line | Dependency | Current | Proposed |
|------|------|------------|---------|----------|
| dockerfiles/go/Dockerfile | 15 | golangci-lint | :latest | :v2.1.6 |
...
```

List any skipped items (unresolved, out-of-scope) separately.

Ask the user to confirm before making any edits.

---

## Phase 4: Pin (Edit Files)

Apply the confirmed changes using these exact transformation rules:

**Docker images (`:latest` → `:vX.Y.Z`):**
- `golangci/golangci-lint:latest` → `golangci/golangci-lint:vX.Y.Z`
- `gomplate/gomplate:latest` → `gomplate/gomplate:vX.Y.Z`
- `goreleaser/goreleaser:latest` → `goreleaser/goreleaser:vX.Y.Z`
- `ghcr.io/astral-sh/uv:debian` → `ghcr.io/astral-sh/uv:X.Y.Z` (version only, no distro suffix; the uv image uses bare semver tags like `0.6.14`)

**GitHub release script URLs:**
- `releases/latest/download/prek-installer.sh` → `releases/download/vX.Y.Z/prek-installer.sh`

**Taskfile install script:**
- `install.sh)" -- -d` → `install.sh)" -- -d -v vX.Y.Z`

**Go module installs:**
- `go-junit-report/v2@latest` → `go-junit-report/v2@vX.Y.Z`

**GitHub Actions (major-only → full semver):**
- `actions/checkout@v6` → `actions/checkout@vN.X.Y`
- `docker/setup-buildx-action@v4` → `docker/setup-buildx-action@vN.X.Y`
- `docker/login-action@v4` → `docker/login-action@vN.X.Y`
- `arduino/setup-task@v2` → `arduino/setup-task@vN.X.Y`

---

## Phase 5: Update renovate.json

Add custom regex managers to `renovate.json` so Renovate tracks deps it can't detect natively. The `dockerfile` and `github-actions` managers from `config:recommended` already handle Docker images and Actions. Only these patterns need custom rules:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "customManagers": [
    {
      "description": "GitHub release download URLs in Dockerfiles",
      "customType": "regex",
      "fileMatch": ["(^|/)Dockerfile$"],
      "matchStrings": [
        "https://github\\.com/(?<depName>[^/]+/[^/]+)/releases/download/(?<currentValue>v[^/]+)/"
      ],
      "datasourceTemplate": "github-releases",
      "versioningTemplate": "semver"
    },
    {
      "description": "Taskfile install script version flag in Dockerfiles",
      "customType": "regex",
      "fileMatch": ["(^|/)Dockerfile$"],
      "matchStrings": [
        "taskfile\\.dev/install\\.sh.*-v (?<currentValue>v[^\\s\"']+)"
      ],
      "depNameTemplate": "go-task/task",
      "datasourceTemplate": "github-releases",
      "versioningTemplate": "semver"
    },
    {
      "description": "go install commands in Dockerfiles",
      "customType": "regex",
      "fileMatch": ["(^|/)Dockerfile$"],
      "matchStrings": [
        "go install (?<depName>[^@]+)@(?<currentValue>v[^\\s]+)"
      ],
      "datasourceTemplate": "go",
      "versioningTemplate": "semver"
    }
  ]
}
```

Write this as the new content of `renovate.json`.

---

## Summary Report

After all edits, print a summary:
- How many dependencies were pinned
- Which files were modified
- Any items that need manual attention (e.g. `claude.ai/install.sh`)
