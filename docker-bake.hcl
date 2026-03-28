group "default" {
    targets = [
        "base",
        "python",
        "go_125",
    ]
}

variable "DOCKER_REPO_URL" {
    type = string
    default = "ghcr.io/ivanklee86/devcontainer"
}

target "base" {
    context = "dockerfiles/base"
    dockerfile = "Dockerfile"
    platforms = ["linux/amd64", "linux/arm64"]
    tags = [
        "${DOCKER_REPO_URL}/base:main",

    ]
    cache-from = ["type=registry,ref=${DOCKER_REPO_URL}/base:cache"]
    cache-to = ["type=registry,ref=${DOCKER_REPO_URL}/base:cache,mode=max"]
}

target "python" {
    contexts = {
        base = "target:base"
    }
    context = "dockerfiles/python"
    dockerfile = "Dockerfile"
    platforms = ["linux/amd64", "linux/arm64"]
    tags = [
        "${DOCKER_REPO_URL}/python:main",
    ]
    cache-from = ["type=registry,ref=${DOCKER_REPO_URL}/python:cache"]
    cache-to = ["type=registry,ref=${DOCKER_REPO_URL}/python:cache,mode=max"]
}

target "go_125" {
    contexts = {
        base = "target:base"
    }
    args = {
        GO_VERSION = "1.25"
    }
    context = "dockerfiles/go"
    dockerfile = "Dockerfile"
    platforms = ["linux/amd64", "linux/arm64"]
    tags = [
        "${DOCKER_REPO_URL}/go:1.25",
    ]
    cache-from = ["type=registry,ref=${DOCKER_REPO_URL}/go:1.25-cache"]
    cache-to = ["type=registry,ref=${DOCKER_REPO_URL}/go:1.25-cache,mode=max"]
}
