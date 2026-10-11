# my-project

## Setup

```
direnv allow .
```

This gives your shell `python`, `uv` and `ruff`. Then create the virtual
environment and install dependencies:

```
uv sync
```

## Everyday use

```
uv run my-project     # run the entry point
uv run pytest         # run the tests
ruff check            # lint
ruff format           # format
uv add <package>      # add a dependency (updates pyproject.toml and uv.lock)
uv add --dev <pkg>    # add a development-only dependency
```

Commit `uv.lock`; it is what makes installs reproducible.

## Notes

- Nix supplies the interpreter and `UV_PYTHON_DOWNLOADS=never` stops uv
  fetching its own, which would not run on NixOS.
- If a wheel fails with a missing `libstdc++.so` / `libz.so`, uncomment the
  `LD_LIBRARY_PATH` block in `flake.nix`.
