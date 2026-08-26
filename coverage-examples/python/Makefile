# Makefile for Python coverage examples
# Demonstrates coverage.py native data and exported report formats.

PYTHON = python3
BUILD_DIR = build
VENV_DIR = $(BUILD_DIR)/venv
VENV_PYTHON = $(VENV_DIR)/bin/python
COVERAGE_DIR = $(BUILD_DIR)/coverage
COVERAGE_DB = .coverage
COVERAGE_JSON = $(COVERAGE_DIR)/coverage.json
COVERAGE_XML = $(COVERAGE_DIR)/coverage.xml
COVERAGE_LCOV = $(COVERAGE_DIR)/coverage.lcov
COVERAGE_HTML_DIR = $(COVERAGE_DIR)/html

.PHONY: help venv test coverage json xml lcov html clean

help:
	@echo "Python Coverage Example"
	@echo ""
	@echo "Targets:"
	@echo "  make venv      - Create build/venv with coverage + pytest installed"
	@echo "  make test      - Run pytest"
	@echo "  make coverage  - Run tests and generate .coverage"
	@echo "  make json      - Export coverage.json"
	@echo "  make xml       - Export coverage.xml (Cobertura)"
	@echo "  make lcov      - Export coverage.lcov"
	@echo "  make html      - Export an HTML coverage report"
	@echo "  make clean     - Remove build artifacts (including the venv)"
	@echo ""
	@echo "Examples:"
	@echo "  $$ make coverage"
	@echo "  $$ make json"
	@echo "  $$ make xml"
	@echo "  $$ make lcov"
	@echo "  $$ make html"

$(COVERAGE_DIR):
	@mkdir -p $(COVERAGE_DIR)

# Many distros (Arch, Debian, Ubuntu) mark the system Python as
# "externally managed", so `pip install coverage pytest` fails there. Use an
# isolated venv instead of requiring --break-system-packages or a pre-existing
# system install. `python -m venv` creates $(BUILD_DIR) as needed.
$(VENV_PYTHON):
	$(PYTHON) -m venv $(VENV_DIR)
	$(VENV_PYTHON) -m pip install -q --upgrade pip
	$(VENV_PYTHON) -m pip install -q coverage pytest
	@echo "✓ venv ready: $(VENV_DIR)"

venv: $(VENV_PYTHON)

test: $(VENV_PYTHON)
	PYTHONPATH=src $(VENV_PYTHON) -m pytest

coverage: $(VENV_PYTHON) $(COVERAGE_DIR)
	PYTHONPATH=src $(VENV_PYTHON) -m coverage run --branch -m pytest
	@echo "✓ coverage.py data generated (with branch coverage): $(COVERAGE_DB)"
	@echo "  Load in crazy-coverage.nvim: :CoverageLoad $(COVERAGE_DB)"

json: coverage
	PYTHONPATH=src $(VENV_PYTHON) -m coverage json -o $(COVERAGE_JSON) --data-file=$(COVERAGE_DB) --pretty-print
	@echo "✓ Coverage JSON generated: $(COVERAGE_JSON)"

xml: coverage
	PYTHONPATH=src $(VENV_PYTHON) -m coverage xml -o $(COVERAGE_XML) --data-file=$(COVERAGE_DB)
	@echo "✓ Cobertura XML generated: $(COVERAGE_XML)"

lcov: coverage
	PYTHONPATH=src $(VENV_PYTHON) -m coverage lcov -o $(COVERAGE_LCOV) --data-file=$(COVERAGE_DB)
	@echo "✓ LCOV generated: $(COVERAGE_LCOV)"

html: coverage
	PYTHONPATH=src $(VENV_PYTHON) -m coverage html -d $(COVERAGE_HTML_DIR) --data-file=$(COVERAGE_DB)
	@echo "✓ HTML report generated: $(COVERAGE_HTML_DIR)/index.html"

clean:
	@rm -rf $(BUILD_DIR) $(COVERAGE_DB) __pycache__ .pytest_cache
	@echo "✓ Build artifacts cleaned"
