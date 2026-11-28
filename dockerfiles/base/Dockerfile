ARG BASE="debian-13"
FROM mcr.microsoft.com/devcontainers/base:${BASE}

# Install system dependencies
RUN apt-get update && apt-get install -y build-essential binutils-gold git-lfs --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
ARG TARGETARCH
# renovate: datasource=github-releases depName=cli/cli
ARG GH_VERSION=v2.106.0
RUN GH_DIR="gh_${GH_VERSION#v}_linux_${TARGETARCH}" && \
    curl -fsSL "https://github.com/cli/cli/releases/download/${GH_VERSION}/${GH_DIR}.tar.gz" \
    | tar -xz -C /usr/local/bin --strip-components=2 --wildcards '*/bin/gh'

# Setup
ENV HOME="/home/vscode"
WORKDIR /home/vscode
USER vscode

# Install prek
# renovate: datasource=github-releases depName=j178/prek
ARG PREK_VERSION=v0.5.11
RUN curl --proto '=https' --tlsv1.2 -LsSf \
    "https://github.com/j178/prek/releases/download/${PREK_VERSION}/prek-installer.sh" | sh

# Install taskfile
# renovate: datasource=github-releases depName=go-task/task
ARG TASK_VERSION=v3.54.0
ENV TASK_X_REMOTE_TASKFILES=1
RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d "${TASK_VERSION}"

# Install Claude Code CLI
# renovate: datasource=npm depName=@anthropic-ai/claude-code
ARG CLAUDE_CODE_VERSION=2.1.332
RUN curl -fsSL https://claude.ai/install.sh | bash -s "${CLAUDE_CODE_VERSION}"
ENV PATH="/home/vscode/.local/bin:${PATH}"

# Install Gantry
COPY --from=ghcr.io/ivanklee86/gantry:0.0.4 /usr/local/bin/gantry /usr/local/bin/gantry

# Install 1Password CLI
COPY --from=1password/op:2.42.0 /usr/local/bin/op /usr/local/bin/op

# Install bun
# renovate: datasource=github-releases depName=oven-sh/bun extractVersion=^bun-v(?<version>.+)$
ARG BUN_VERSION=1.4.5
ENV BUN_INSTALL="/home/vscode/.bun"
ENV PATH="/home/vscode/.bun/bin:${PATH}"
RUN curl -fsSL https://bun.sh/install | bash -s "bun-v${BUN_VERSION}"

# Install ccusage
# renovate: datasource=npm depName=ccusage
ARG CCUSAGE_VERSION=20.1.2
RUN bun install -g ccusage@${CCUSAGE_VERSION}

# Install uv and Python (Claude Code reaches for Python a lot)
ENV UV_CACHE_DIR="/home/vscode/.uv_cache"
ENV UV_LINK_MODE=copy
COPY --from=ghcr.io/astral-sh/uv:0.13.10-debian /usr/local/bin/uv /usr/local/bin
COPY --from=ghcr.io/astral-sh/uv:0.13.10-debian /usr/local/bin/uvx /usr/local/bin
# `--default` also links `python` / `python3` into ~/.local/bin; the others get only `python3.x`.
ARG DEFAULT_PYTHON_VERSION=3.14
ARG EXTRA_PYTHON_VERSIONS="3.15"
RUN uv python install ${EXTRA_PYTHON_VERSIONS} && \
    uv python install --preview-features python-install-default --default ${DEFAULT_PYTHON_VERSION}

# Enable the ccusage statusline by default
COPY --chown=vscode:vscode claude-settings.json /home/vscode/.claude/settings.json
