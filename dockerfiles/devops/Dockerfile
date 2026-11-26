FROM base

# -- Terraform
ENV TENV_AUTO_INSTALL=true

# - Install tenv
ARG TARGETARCH
USER root
# renovate: datasource=github-releases depName=tofuutils/tenv
ARG TENV_VERSION=v4.16.9
RUN TENV_URL="https://github.com/tofuutils/tenv/releases/download/${TENV_VERSION}/tenv_${TENV_VERSION}_${TARGETARCH}.deb" && \
    curl -O -L "$TENV_URL" && \
    dpkg -i "${TENV_URL##*/}" && \
    rm -f "${TENV_URL##*/}"

# renovate: datasource=github-releases depName=google/go-jsonnet
ARG JSONNET_VERSION=v0.22.0
RUN JSONNET_URL="https://github.com/google/go-jsonnet/releases/download/${JSONNET_VERSION}/jsonnet-go_${JSONNET_VERSION#v}_linux_${TARGETARCH}.deb" && \
    curl -O -L "$JSONNET_URL" && \
    dpkg -i "${JSONNET_URL##*/}" && \
    rm -f "${JSONNET_URL##*/}"

# - Install k9s (quay.io/derailed/k9s image stopped publishing at v0.50.4)
# renovate: datasource=github-releases depName=derailed/k9s
ARG K9S_VERSION=v0.51.0
RUN K9S_URL="https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_linux_${TARGETARCH}.deb" && \
    curl -O -L "$K9S_URL" && \
    dpkg -i "${K9S_URL##*/}" && \
    rm -f "${K9S_URL##*/}"

# renovate: datasource=github-tags depName=aws/aws-cli
ARG AWS_CLI_VERSION=2.42.4
RUN ARCH=$([ "${TARGETARCH}" = "amd64" ] && echo "x86_64" || echo "aarch64") && \
    curl -O -L "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}-${AWS_CLI_VERSION}.zip" && \
    unzip "awscli-exe-linux-${ARCH}-${AWS_CLI_VERSION}.zip" && \
    ./aws/install && \
    rm -rf aws "awscli-exe-linux-${ARCH}-${AWS_CLI_VERSION}.zip"

USER vscode

# - Install Terraform tools
COPY --from=quay.io/terraform-docs/terraform-docs:0.25.1 /usr/local/bin/terraform-docs /usr/local/bin
COPY --from=ghcr.io/terraform-linters/tflint:v0.66.0 /usr/local/bin/tflint /usr/local/bin

# - Install Kubernetes tools
COPY --from=registry.k8s.io/kubectl:v1.37.3 /bin/kubectl /usr/local/bin/kubectl
COPY --from=alpine/helm:4.3.2 /usr/bin/helm /usr/local/bin/helm
COPY --from=grafana/tanka:0.40.2 /usr/local/bin/tk /usr/local/bin/tk
COPY --from=grafana/tanka:0.40.2 /usr/local/bin/jb /usr/local/bin/jb
