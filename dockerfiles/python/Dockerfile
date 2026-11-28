FROM base

# uv, Python 3.14 (the default) and 3.15 come from base. This re-asserts the Python version the
# image is tagged with as the default `python` / `python3`, so the tag stays true if base's default moves.
# Keep in sync with the python:<version> tag in docker-bake.hcl and devcontainer_configs/bases/python.
ARG PYTHON_VERSION=3.14
RUN uv python install --preview-features python-install-default --default ${PYTHON_VERSION}
