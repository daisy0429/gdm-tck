#!/usr/bin/env bash
# GDM TCK 测试套件运行脚本
# 用法:
#   ./scripts/run_suite.sh <suite> [options]
#   ./scripts/run_suite.sh --features <features_path> [options]
# 套件: tck, clauses, expressions, ddl, dml, index, constraint, national_std, capacity, functional, performance, all
# --features: 指定 features/ 下的子路径执行用例
#   例如: --features 0-opencypher/clauses/match
#         --features 1-metadata/Concurrent

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

ALLURE_DIR="${GDM_TCK_REPORT__ALLURE_RESULTS_DIR:-allure-results}"

if [[ "${1:-}" == "--features" ]]; then
    FEATURES_PATH="${2:-}"
    if [[ -z "$FEATURES_PATH" ]]; then
        echo "Error: --features 需要指定路径参数"
        echo "用法: $0 --features <features_path> [options]"
        echo "例如: $0 --features 0-opencypher/clauses/match"
        exit 1
    fi
    shift 2 || true
    # Strip leading -- if present (convention for separating script args from pytest args)
    [[ "${1:-}" == "--" ]] && shift || true
    EXTRA_ARGS="${*:-}"
    echo "=== Running features: ${FEATURES_PATH} ==="
    uv run pytest tests/tck/ \
        --features="$FEATURES_PATH" \
        --alluredir="$ALLURE_DIR" \
        $EXTRA_ARGS
    echo "=== Features '$FEATURES_PATH' completed ==="
    echo "Allure results at: $ALLURE_DIR"
    exit 0
fi

SUITE="${1:-all}"
shift || true
# Strip leading -- if present
[[ "${1:-}" == "--" ]] && shift || true
EXTRA_ARGS="${*:-}"

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
    capacity)
        run_pytest "capacity" "tests/tck/test_capacity.py"
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
        echo "Available: tck, clauses, expressions, ddl, dml, index, constraint, national_std, capacity, functional, performance, all"
        echo "Or use: --features <path>  (e.g. --features 0-opencypher/clauses/match)"
        exit 1
        ;;
esac

echo "=== Suite '$SUITE' completed ==="
echo "Allure results at: $ALLURE_DIR"
