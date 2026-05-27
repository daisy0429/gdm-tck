"""结果比较器模块。

提供 TCK 测试中各种结果比较策略的实现：
- 无序比较 (any order)
- 有序比较 (in order)
- 包含检查 (contains)
- 空结果断言
"""

from __future__ import annotations

import json
from typing import Any

from ..exceptions import ResultComparisonError
from .converter import convert_bolt_record
from .parser import parse_tck_value


def assert_result_equal_any_order(
    actual_records: list[dict[str, Any]],
    actual_keys: list[str],
    expected_header: list[str],
    expected_rows: list[list[str]],
) -> None:
    """断言结果集与期望相等（忽略行顺序）。

    Args:
        actual_records: 查询返回的记录列表。
        actual_keys: 结果列名。
        expected_header: 期望的列名列表。
        expected_rows: 期望的行数据（TCK 文本格式）。

    Raises:
        ResultComparisonError: 比较失败时抛出。
    """
    _validate_headers(actual_keys, expected_header)
    actual_normalized = _normalize_actual(actual_records, expected_header)
    expected_normalized = _normalize_expected(expected_header, expected_rows)
    _compare_any_order(actual_normalized, expected_normalized)


def assert_result_equal_in_order(
    actual_records: list[dict[str, Any]],
    actual_keys: list[str],
    expected_header: list[str],
    expected_rows: list[list[str]],
) -> None:
    """断言结果集与期望相等（保持行顺序）。

    Args:
        actual_records: 查询返回的记录列表。
        actual_keys: 结果列名。
        expected_header: 期望的列名列表。
        expected_rows: 期望的行数据（TCK 文本格式）。

    Raises:
        ResultComparisonError: 比较失败时抛出。
    """
    _validate_headers(actual_keys, expected_header)
    actual_normalized = _normalize_actual(actual_records, expected_header)
    expected_normalized = _normalize_expected(expected_header, expected_rows)
    _compare_in_order(actual_normalized, expected_normalized)


def assert_result_contains(
    actual_records: list[dict[str, Any]],
    actual_keys: list[str],
    expected_header: list[str],
    expected_rows: list[list[str]],
) -> None:
    """断言结果集包含所有期望行（可有额外行）。

    Args:
        actual_records: 查询返回的记录列表。
        actual_keys: 结果列名。
        expected_header: 期望的列名列表。
        expected_rows: 期望的行数据（TCK 文本格式）。

    Raises:
        ResultComparisonError: 比较失败时抛出。
    """
    _validate_headers(actual_keys, expected_header)
    actual_normalized = _normalize_actual(actual_records, expected_header)
    expected_normalized = _normalize_expected(expected_header, expected_rows)

    actual_set = {_row_to_comparable(row) for row in actual_normalized}
    for row in expected_normalized:
        comparable = _row_to_comparable(row)
        if comparable not in actual_set:
            raise ResultComparisonError(
                "Expected row not found in actual results",
                expected=row,
                actual=actual_normalized,
            )


def assert_result_empty(
    actual_records: list[dict[str, Any]],
) -> None:
    """断言结果集为空。

    Args:
        actual_records: 查询返回的记录列表。

    Raises:
        ResultComparisonError: 结果非空时抛出。
    """
    if actual_records:
        raise ResultComparisonError(
            f"Expected empty result but got {len(actual_records)} rows",
            expected=[],
            actual=actual_records,
        )


def _validate_headers(actual_keys: list[str], expected_header: list[str]) -> None:
    """验证列名匹配。"""
    if not expected_header:
        return
    if actual_keys != expected_header:
        raise ResultComparisonError(
            "Result headers do not match",
            expected=expected_header,
            actual=actual_keys,
        )


def _normalize_actual(records: list[dict[str, Any]], header: list[str]) -> list[dict[str, Any]]:
    """将实际结果标准化为可比较格式。"""
    normalized = []
    for record in records:
        converted = convert_bolt_record(record)
        # 按 header 顺序提取值
        row = {}
        for key in header:
            row[key] = converted.get(key)
        normalized.append(row)
    return normalized


def _normalize_expected(header: list[str], rows: list[list[str]]) -> list[dict[str, Any]]:
    """将期望数据解析为标准化格式。"""
    normalized = []
    for row in rows:
        parsed = {}
        for i, key in enumerate(header):
            value = row[i] if i < len(row) else ""
            parsed[key] = parse_tck_value(value)
        normalized.append(parsed)
    return normalized


def _row_to_comparable(row: dict[str, Any]) -> str:
    """将行字典转为可哈希的比较字符串。递归排序列表和字典键以确保稳定比较。"""
    return json.dumps(_normalize_for_comparison(row), sort_keys=True, default=str)


def _normalize_for_comparison(value: Any) -> Any:
    """递归规范化值以便稳定比较：排序列表元素和字典键。"""
    if isinstance(value, dict):
        return {k: _normalize_for_comparison(v) for k, v in value.items()}
    if isinstance(value, list):
        normalized = [_normalize_for_comparison(item) for item in value]
        try:
            return sorted(normalized, key=_sort_key)
        except TypeError:
            return normalized
    # 规范化 -0.0 为 0.0（IEEE 754 中它们数学上相等）
    if isinstance(value, float) and value == 0.0:
        return 0.0
    return value


def _sort_key(value: Any) -> Any:
    """为 sorted() 提供排序键，处理混合类型列表。"""
    if isinstance(value, dict):
        return json.dumps(value, sort_keys=True, default=str)
    if isinstance(value, list):
        return json.dumps(value, sort_keys=True, default=str)
    if isinstance(value, bool):
        return (0, int(value))
    if isinstance(value, (int, float)):
        return (0, value)
    if isinstance(value, str):
        return (1, value)
    if value is None:
        return (-1,)
    return (2, str(value))


def _compare_any_order(actual: list[dict], expected: list[dict]) -> None:
    """无序比较两组行。"""
    if len(actual) != len(expected):
        raise ResultComparisonError(
            f"Row count mismatch: expected {len(expected)}, got {len(actual)}",
            expected=expected,
            actual=actual,
        )
    actual_sorted = sorted(_row_to_comparable(r) for r in actual)
    expected_sorted = sorted(_row_to_comparable(r) for r in expected)
    if actual_sorted != expected_sorted:
        raise ResultComparisonError(
            "Results do not match (any order comparison)",
            expected=expected,
            actual=actual,
        )


def _compare_in_order(actual: list[dict], expected: list[dict]) -> None:
    """有序比较两组行。"""
    if len(actual) != len(expected):
        raise ResultComparisonError(
            f"Row count mismatch: expected {len(expected)}, got {len(actual)}",
            expected=expected,
            actual=actual,
        )
    for i, (act, exp) in enumerate(zip(actual, expected)):
        if _row_to_comparable(act) != _row_to_comparable(exp):
            raise ResultComparisonError(
                f"Row {i} does not match",
                expected=exp,
                actual=act,
            )
