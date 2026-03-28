group "default" {
    targets = [
        "base",
        "python",
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
        "${DOCKER_REPO_URL}/base:latest",
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
        "${DOCKER_REPO_URL}/python:latest",
    ]
    cache-from = ["type=registry,ref=${DOCKER_REPO_URL}/python:cache"]
    cache-to = ["type=registry,ref=${DOCKER_REPO_URL}/python:cache,mode=max"]
}
