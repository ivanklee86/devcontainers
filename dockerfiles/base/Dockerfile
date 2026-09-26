ARG BASE="debian-13"
FROM mcr.microsoft.com/devcontainers/base:${BASE}

# Install system dependencies
RUN apt-get update && apt-get install -y build-essential binutils-gold git-lfs --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
ARG TARGETARCH
# renovate: datasource=github-releases depName=cli/cli
ARG GH_VERSION=v2.101.0
RUN GH_DIR="gh_${GH_VERSION#v}_linux_${TARGETARCH}" && \
    curl -fsSL "https://github.com/cli/cli/releases/download/${GH_VERSION}/${GH_DIR}.tar.gz" \
    | tar -xz -C /usr/local/bin --strip-components=2 --wildcards '*/bin/gh'

# Setup
ENV HOME="/home/vscode"
WORKDIR /home/vscode
USER vscode

# Install prek
# renovate: datasource=github-releases depName=j178/prek
ARG PREK_VERSION=v0.5.3
RUN curl --proto '=https' --tlsv1.2 -LsSf \
    "https://github.com/j178/prek/releases/download/${PREK_VERSION}/prek-installer.sh" | sh

# Install taskfile
# renovate: datasource=github-releases depName=go-task/task
ARG TASK_VERSION=v3.53.1
ENV TASK_X_REMOTE_TASKFILES=1
RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d "${TASK_VERSION}"

# Install Claude Code CLI
# renovate: datasource=npm depName=@anthropic-ai/claude-code
ARG CLAUDE_CODE_VERSION=2.1.278
RUN curl -fsSL https://claude.ai/install.sh | bash -s "${CLAUDE_CODE_VERSION}"
ENV PATH="/home/vscode/.local/bin:${PATH}"

# Install Gantry
COPY --from=ghcr.io/ivanklee86/gantry:0.0.4 /usr/local/bin/gantry /usr/local/bin/gantry

# Install 1Password CLI
COPY --from=1password/op:2.39.0 /usr/local/bin/op /usr/local/bin/op

# Install bun
# renovate: datasource=github-releases depName=oven-sh/bun extractVersion=^bun-v(?<version>.+)$
ARG BUN_VERSION=1.4.2
ENV BUN_INSTALL="/home/vscode/.bun"
ENV PATH="/home/vscode/.bun/bin:${PATH}"
RUN curl -fsSL https://bun.sh/install | bash -s "bun-v${BUN_VERSION}"

# Install ccusage
# renovate: datasource=npm depName=ccusage
ARG CCUSAGE_VERSION=20.0.24
RUN bun install -g ccusage@${CCUSAGE_VERSION}

# Enable the ccusage statusline by default
COPY --chown=vscode:vscode claude-settings.json /home/vscode/.claude/settings.json
