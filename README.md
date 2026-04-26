# devcontainers

Ivan's opinionated devcontainers!

## Development

### Adding a new devcontainer
1. Create a new Dockerfile in `dockerfiles/` folder.
2. Auth to Github Docker Registry locally.  (PAT requires `write:packages` scope.)
```sh
export GITHUB_PAT="YOUR_GITHUB_PAT"

echo $GITHUB_PAT | docker login ghcr.io -u <GITHUB_USERNAME> --password-stdin`
```
3. Run `task build:push` to create the repository.
4. Update permissions (allow actions from this repository to publish with `Write` permissions, set visibility to `Public`.) on the new repository.
