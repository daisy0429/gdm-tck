#!/usr/bin/env bash
# Allure 报告生成脚本
# 用法: ./scripts/generate_report.sh [allure-results-dir] [output-dir]

set -euo pipefail

ALLURE_RESULTS="${1:-allure-results}"
ALLURE_REPORT="${2:-allure-report}"

if ! command -v allure &>/dev/null; then
    echo "Error: allure command not found."
    echo "Install: brew install allure (macOS) or see https://docs.qameta.io/allure/"
    exit 1
fi

if [ ! -d "$ALLURE_RESULTS" ]; then
    echo "Error: Results directory not found: $ALLURE_RESULTS"
    echo "Run tests first: ./scripts/run_suite.sh <suite>"
    exit 1
fi

echo "Generating Allure report..."
allure generate "$ALLURE_RESULTS" -o "$ALLURE_REPORT" --clean

echo "Report generated at: $ALLURE_REPORT"
echo ""
echo "To view in browser:"
echo "  allure open $ALLURE_REPORT"
echo ""
echo "Or serve temporarily:"
echo "  allure serve $ALLURE_RESULTS"
