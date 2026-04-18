ARG GO_VERSION=1.26
FROM golang:${GO_VERSION} as go

FROM base

# -- Terraform
ENV TENV_AUTO_INSTALL=true

# Install Go
ENV GOTOOLCHAIN=auto
COPY --from=go /usr/local/go/ /usr/local/go/
ENV GOPATH=/home/vscode/go
ENV PATH=/usr/local/go/bin:$GOPATH/bin:/home/vscode/.local/bin:$PATH
# - Golang
COPY --from=golangci/golangci-lint:v2.11.4 /usr/bin/golangci-lint /usr/local/bin
RUN go install github.com/jstemmer/go-junit-report/v2@v2.1.0
COPY --from=gomplate/gomplate:v5.0.0 /gomplate /usr/local/bin/gomplate
COPY --from=goreleaser/goreleaser:v2.15.3 /usr/bin/goreleaser /usr/local/bin
