FROM base

# -- Terraform
ENV TENV_AUTO_INSTALL=true

# - Install tenv
ARG TARGETARCH
USER root
ARG TENV_VERSION=v4.10.1
RUN TENV_URL="https://github.com/tofuutils/tenv/releases/download/${TENV_VERSION}/tenv_${TENV_VERSION}_${TARGETARCH}.deb" && \
    curl -O -L "$TENV_URL" && \
    dpkg -i "${TENV_URL##*/}" && \
    rm -f "${TENV_URL##*/}"

ARG JSONNET_VERSION=v0.22.0
RUN JSONNET_URL="https://github.com/google/go-jsonnet/releases/download/${JSONNET_VERSION}/jsonnet-go_${JSONNET_VERSION#v}_linux_${TARGETARCH}.deb" && \
    curl -O -L "$JSONNET_URL" && \
    dpkg -i "${JSONNET_URL##*/}" && \
    rm -f "${JSONNET_URL##*/}"

ARG AWS_CLI_VERSION=2.34.37
RUN ARCH=$([ "${TARGETARCH}" = "amd64" ] && echo "x86_64" || echo "aarch64") && \
    curl -O -L "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}-${AWS_CLI_VERSION}.zip" && \
    unzip "awscli-exe-linux-${ARCH}-${AWS_CLI_VERSION}.zip" && \
    ./aws/install && \
    rm -rf aws "awscli-exe-linux-${ARCH}-${AWS_CLI_VERSION}.zip"

USER vscode

# - Install Python with uv, exposed as `python` and `python3`
# Keep in sync with PYTHON_VERSION in dockerfiles/python/Dockerfile.
ARG PYTHON_VERSION=3.14
RUN uv python install --default ${PYTHON_VERSION}

# - Install yq
COPY --from=mikefarah/yq:4.54.1 /usr/bin/yq /usr/local/bin/yq

# - Install Terraform tools
COPY --from=quay.io/terraform-docs/terraform-docs:0.20.0 /usr/local/bin/terraform-docs /usr/local/bin
COPY --from=ghcr.io/terraform-linters/tflint:v0.65.0 /usr/local/bin/tflint /usr/local/bin

# - Install Kubernetes tools
COPY --from=registry.k8s.io/kubectl:v1.37.2 /bin/kubectl /usr/local/bin/kubectl
COPY --from=alpine/helm:4.3.1 /usr/bin/helm /usr/local/bin/helm
COPY --from=grafana/tanka:0.39.5 /usr/local/bin/tk /usr/local/bin/tk
COPY --from=grafana/tanka:0.39.5 /usr/local/bin/jb /usr/local/bin/jb
COPY --from=quay.io/derailed/k9s:v0.50.4 /bin/k9s /usr/local/bin/k9s
