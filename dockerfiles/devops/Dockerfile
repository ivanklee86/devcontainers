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

USER vscode

# - Install Terraform tools
COPY --from=quay.io/terraform-docs/terraform-docs:0.20.0 /usr/local/bin/terraform-docs /usr/local/bin
COPY --from=ghcr.io/terraform-linters/tflint:v0.61.0 /usr/local/bin/tflint /usr/local/bin

# - Install Kubernetes tools
COPY --from=registry.k8s.io/kubectl:v1.36.0 /bin/kubectl /usr/local/bin/kubectl
COPY --from=alpine/helm:4.1.4 /usr/bin/helm /usr/local/bin/helm
COPY --from=grafana/tanka:v0.37.0 /usr/bin/tk /usr/local/bin/tk
COPY --from=grafana/tanka:v0.37.0 /usr/bin/jsonnet /usr/local/bin/jsonnet
COPY --from=grafana/tanka:v0.37.0 /usr/bin/jb /usr/local/bin/jb
COPY --from=quay.io/derailed/k9s:v0.50.18 /bin/k9s /usr/local/bin/k9s
