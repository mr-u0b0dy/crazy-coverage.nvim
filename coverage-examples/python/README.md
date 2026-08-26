# Python Coverage Example

This example shows crazy-coverage.nvim with coverage.py outputs.

## Structure

- `src/math_utils.py` - sample code with line and branch coverage
- `tests/test_math_utils.py` - pytest coverage tests
- `Makefile` - coverage generation targets
- `pyproject.toml` - pytest configuration

## Quick Start

```bash
cd python
make test
make coverage
make xml
make json
make lcov
make html
```

`make test`/`make coverage` create an isolated virtualenv at `build/venv` on first run and install
`coverage` + `pytest` into it automatically — no manual setup required. Run `make venv` to create it
without running tests, or `make clean` to remove it along with other build artifacts.

## Supported Outputs

| Format | File | Load Command |
|--------|------|--------------|
| Native coverage.py data | `.coverage` | `:CoverageLoad .coverage` |
| Coverage.py JSON | `build/coverage/coverage.json` | `:CoverageLoad build/coverage/coverage.json` |
| Cobertura XML | `build/coverage/coverage.xml` | `:CoverageLoad build/coverage/coverage.xml` |
| LCOV | `build/coverage/coverage.lcov` | `:CoverageLoad build/coverage/coverage.lcov` |

`make html` generates a browsable HTML report at `build/coverage/html/index.html` (open it in a
browser) — it's a coverage.py convenience output, not a format crazy-coverage.nvim loads.

## Requirements

- Python 3.10+ (with the standard `venv` module available)

`coverage` and `pytest` do not need to be installed beforehand — the Makefile provisions its own
virtualenv (`build/venv`) and installs them there. This also sidesteps "externally managed
environment" errors from `pip install` on distros like Arch, Debian, or Ubuntu.

If you'd rather use a pre-existing environment (a `conda`/`pyenv` env, another virtualenv, or a
system Python where `pip install` is unrestricted), install `coverage`/`pytest` into it and run the
underlying commands directly instead of through `make`:

```bash
python3 -m pip install coverage pytest
PYTHONPATH=src python3 -m coverage run -m pytest
```
