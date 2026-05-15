# AGENTS.md -- gdm-tck workspace

## Project Overview

GDM TCK (Technology Compatibility Kit) test framework. Python + pytest-bdd based BDD test project targeting the GDM graph database product.

**Tech Stack:** Python 3.11+, pytest-bdd, neo4j driver, allure-pytest, uv

## Quick Start

```bash
# Install dependencies
uv sync

# Run all TCK tests (requires GDM instance)
uv run pytest tests/tck/ --alluredir=allure-results

# Run specific suite
./scripts/run_suite.sh clauses

# Run capacity suite (currently placeholder scenarios only)
./scripts/run_suite.sh capacity

# Collect tests without executing (verify framework)
uv run pytest tests/ --co

# Generate Allure report
./scripts/generate_report.sh
```

## Configuration

All configuration in `config/default.toml`. Override via:
- Additional TOML file: `GDM_TCK_CONFIG=config/ci.toml`
- Environment variables: `GDM_TCK_SERVER__BOLT_URI=bolt://host:port`

Key settings:
- `server.bolt_uri` - GDM Bolt endpoint
- `server.username` / `server.password` - Authentication
- `server.database` - Target database name
- `server.mode` - standalone or distributed

## Architecture

```
src/gdm_tck/         Core library
  config.py          Configuration loading (TOML + env)
  exceptions.py      Custom exception hierarchy
  state.py           ScenarioContext (per-scenario state isolation)
  connection/        Bolt client, connection pool, GDM agent patch
  result/            TCK value parser, result converter, comparators
  concurrent/        Thread-based concurrent execution
  server/            Health checks, lifecycle management
  reporting/         Allure hooks, run summary

steps/               pytest-bdd step definitions (by feature domain)
features/            Gherkin .feature files (from cypher-tck)
tests/               Test collection modules
  tck/               BDD test collectors (one per feature category)
  functional/        Non-BDD supplementary tests
  performance/       Throughput and latency benchmarks
```

## Adding New Tests

### Add a new feature file
1. Place `.feature` file in appropriate `features/` subdirectory
2. If new step patterns are needed, add to relevant `steps/step_*.py`
3. The existing `tests/tck/test_*.py` collector will auto-discover it

### Add a new test module
1. Create `features/<module>/` directory with `.feature` files
2. Create `tests/tck/test_<module>.py` with `scenarios()` call
3. Add pytest marker to `pyproject.toml` if needed

## Running Tests

```bash
# Single feature category
uv run pytest tests/tck/test_clauses.py -v

# Run by features/ subdirectory path (--features option)
uv run pytest tests/tck/ --features=0-original
uv run pytest tests/tck/ --features=0-original/clauses/match
uv run pytest tests/tck/ --features=1-metadata/Concurrent
uv run pytest tests/tck/ --features=.

# Via run_suite.sh
./scripts/run_suite.sh --features 0-original/clauses/match
./scripts/run_suite.sh --features 1-metadata/Concurrent -- -v -n 4

# With tag filtering
uv run pytest tests/tck/ -k "not ignore"

# Parallel execution
uv run pytest tests/tck/ -n 4

# With Allure reporting
uv run pytest tests/ --alluredir=allure-results
```

### --features option

The `--features` option allows running tests from any subdirectory under `features/`. It recursively discovers all `.feature` files under the specified path. When combined with the existing test collectors, it filters to only run scenarios from matching `.feature` files.

When no `--features` is specified, all existing `test_*.py` collectors work as before (fully backward compatible).

## Gotchas

- GDM returns "GDM/" server agent prefix. The `agent_patch` module auto-patches neo4j driver to accept it.
- Feature files use `"""` docstrings for Cypher queries. pytest-bdd handles these as step arguments.
- `ScenarioContext` is function-scoped: each scenario gets a fresh state instance.
- In distributed mode, `server.bolt_uris` must list all node URIs.
