ARG GO_VERSION=1.25
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
COPY --from=golangci/golangci-lint:latest /usr/bin/golangci-lint /usr/local/bin
RUN go install github.com/jstemmer/go-junit-report/v2@latest
COPY --from=gomplate/gomplate:latest /gomplate /usr/local/bin/gomplate
COPY --from=goreleaser/goreleaser:latest /usr/bin/goreleaser /usr/local/bin
