# devcontainers

Ivan's opinionated devcontainers!

## Development

### Adding a new devcontainer
1. Create a new Dockerfile in `dockerfiles/` folder.
2. Auth to Github Docker Registry locally.
3. Run `task build:push` to create the repository.
4. Update permissions (allow actions from this repository to publish with `Write` permissions, set visibility to `Public`.) on the new repository.
