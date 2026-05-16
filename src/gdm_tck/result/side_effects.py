"""副作用断言模块。

验证查询执行后的统计副作用计数器（节点/关系/标签/属性的增减）。
"""

from __future__ import annotations

from typing import Any

import neo4j

from ..exceptions import SideEffectError

# 副作用计数器字段映射
SIDE_EFFECT_KEYS = {
    "+nodes": "nodes_created",
    "-nodes": "nodes_deleted",
    "+relationships": "relationships_created",
    "-relationships": "relationships_deleted",
    "+labels": "labels_added",
    "-labels": "labels_removed",
    "+properties": "properties_set",
    "-properties": "properties_set",  # neo4j 没有单独的 properties_removed
    "+constraints": "constraints_added",
    "-constraints": "constraints_removed",
    "+indexes": "indexes_added",
    "-indexes": "indexes_removed",
}


def assert_side_effects(summary: neo4j.ResultSummary | None,
                        expected: dict[str, int]) -> None:
    """断言查询副作用与期望匹配。

    Args:
        summary: neo4j 查询结果摘要。
        expected: 期望的副作用字典，如 {"+nodes": 1, "+labels": 1}。

    Raises:
        SideEffectError: 副作用不匹配时抛出。
    """
    if summary is None:
        if expected:
            raise SideEffectError(
                f"No result summary available, but expected side effects: {expected}"
            )
        return

    counters = summary.counters
    for effect_key, expected_count in expected.items():
        actual_count = _get_counter_value(counters, effect_key)
        if actual_count != expected_count:
            raise SideEffectError(
                f"Side effect mismatch for '{effect_key}': "
                f"expected {expected_count}, got {actual_count}"
            )


def assert_no_side_effects(summary: neo4j.ResultSummary | None) -> None:
    """断言查询没有产生任何副作用。

    Args:
        summary: neo4j 查询结果摘要。

    Raises:
        SideEffectError: 有副作用时抛出。
    """
    if summary is None:
        return
    if summary.counters.contains_updates:
        raise SideEffectError(
            f"Expected no side effects, but found updates: {_counters_to_dict(summary.counters)}"
        )


def _get_counter_value(counters: Any, effect_key: str) -> int:
    """从 counters 对象获取指定副作用的计数值。"""
    attr_name = SIDE_EFFECT_KEYS.get(effect_key)
    if attr_name is None:
        return 0
    return getattr(counters, attr_name, 0)


def _counters_to_dict(counters: Any) -> dict[str, int]:
    """将 counters 对象转为可读字典（仅包含非零值）。"""
    result = {}
    for effect_key, attr_name in SIDE_EFFECT_KEYS.items():
        value = getattr(counters, attr_name, 0)
        if value:
            result[effect_key] = value
    return result


def parse_side_effects_table(rows: list[list[str]]) -> dict[str, int]:
    """解析 Gherkin 表格中的副作用数据。

    表格格式：
    | +nodes | 1 |
    | +relationships | 2 |

    Args:
        rows: 表格行列表，每行为 [key, value]。

    Returns:
        解析后的副作用字典。
    """
    effects = {}
    for row in rows:
        if len(row) >= 2:
            key = row[0].strip()
            value = int(row[1].strip())
            effects[key] = value
    return effects
