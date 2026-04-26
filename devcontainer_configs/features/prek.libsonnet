{
  "postCreateCommand"+: {
    "install-prek": "mkdir -p /home/vscode/.uv_cache && uv venv --clear && uv tool install pre-commit && uv run pre-commit install && uv run pre-commit",
  }
}
