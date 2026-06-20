ARG BASE="debian-13"
FROM mcr.microsoft.com/devcontainers/base:${BASE}

# Install system dependencies
RUN apt-get update && apt-get install -y build-essential binutils-gold git-lfs --no-install-recommends

# Setup
ENV HOME="/home/vscode"
WORKDIR /home/vscode
USER vscode

# Install prek
RUN curl --proto '=https' --tlsv1.2 -LsSf https://github.com/j178/prek/releases/download/v0.4.4/prek-installer.sh | sh

# Install taskfile
ENV TASK_X_REMOTE_TASKFILES=1
RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d v3.51.1

# Install Claude Code CLI
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/vscode/.local/bin:${PATH}"

# Install Gantry
COPY --from=ghcr.io/ivanklee86/gantry:0.0.4 /usr/local/bin/gantry /usr/local/bin/gantry

# Install 1Password CLI
COPY --from=1password/op:2.34.1 /usr/local/bin/op /usr/local/bin/op

# Install bun
# renovate: datasource=github-releases depName=oven-sh/bun extractVersion=^bun-v(?<version>.+)$
ARG BUN_VERSION=1.3.14
ENV BUN_INSTALL="/home/vscode/.bun"
ENV PATH="/home/vscode/.bun/bin:${PATH}"
RUN curl -fsSL https://bun.sh/install | bash -s "bun-v${BUN_VERSION}"

# Install opencode
# renovate: datasource=npm depName=opencode-ai
ARG OPENCODE_VERSION=1.17.7
RUN bun install -g opencode-ai@${OPENCODE_VERSION}
