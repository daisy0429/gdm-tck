#!/usr/bin/env bash
# GDM TCK 测试套件运行脚本
# 用法: ./scripts/run_suite.sh <suite> [options]
# 套件: tck, clauses, expressions, ddl, dml, index, constraint, national_std, functional, performance, all

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

SUITE="${1:-all}"
shift || true
EXTRA_ARGS="${*:-}"

ALLURE_DIR="${GDM_TCK_REPORT__ALLURE_RESULTS_DIR:-allure-results}"

run_pytest() {
    local marker="$1"
    local path="$2"
    echo "=== Running suite: ${SUITE} (marker: ${marker}, path: ${path}) ==="
    uv run pytest "$path" \
        --alluredir="$ALLURE_DIR" \
        $EXTRA_ARGS
}

case "$SUITE" in
    tck)
        run_pytest "tck" "tests/tck/"
        ;;
    clauses)
        run_pytest "tck" "tests/tck/test_clauses.py"
        ;;
    expressions)
        run_pytest "tck" "tests/tck/test_expressions.py"
        ;;
    ddl)
        run_pytest "ddl" "tests/tck/test_ddl.py"
        ;;
    dml)
        run_pytest "dml" "tests/tck/test_dml.py"
        ;;
    index)
        run_pytest "index" "tests/tck/test_index.py"
        ;;
    constraint)
        run_pytest "constraint" "tests/tck/test_constraint.py"
        ;;
    national_std)
        run_pytest "national_standard" "tests/tck/test_national_std.py"
        ;;
    functional)
        run_pytest "functional" "tests/functional/"
        ;;
    performance)
        run_pytest "performance" "tests/performance/"
        ;;
    all)
        run_pytest "" "tests/"
        ;;
    *)
        echo "Unknown suite: $SUITE"
        echo "Available: tck, clauses, expressions, ddl, dml, index, constraint, national_std, functional, performance, all"
        exit 1
        ;;
esac

echo "=== Suite '$SUITE' completed ==="
echo "Allure results at: $ALLURE_DIR"
