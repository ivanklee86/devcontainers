FROM base

# Install and configure Python
ENV UV_CACHE_DIR="/home/vscode/.uv_cache"
COPY --from=ghcr.io/astral-sh/uv:0.13.6-debian /usr/local/bin/uv /usr/local/bin
COPY --from=ghcr.io/astral-sh/uv:0.13.6-debian /usr/local/bin/uvx /usr/local/bin
# Keep in sync with the python:<version> tag in docker-bake.hcl, devcontainer_configs/bases/python and dockerfiles/devops.
ARG PYTHON_VERSION=3.14
RUN uv python install ${PYTHON_VERSION}
ENV UV_LINK_MODE=copy
