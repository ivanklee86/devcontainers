group "default" {
    targets = [
        "base",
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
