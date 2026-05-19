"""执行计划断言 step definitions。

对应 Gherkin 中的 Then 步骤：
- the plan of query should contain "{operator}":\n<cypher>
- the plan of query should not contain "{operator}":\n<cypher>

通过在用户给定的 Cypher 前自动添加 EXPLAIN 前缀执行查询，
然后在所有返回行的所有字段值中搜索目标操作符字符串，
据此断言执行计划是否包含/不含指定操作符。
"""

from __future__ import annotations

import logging
from typing import Any

from pytest_bdd import parsers, then

from gdm_tck.connection import BoltConnectionPool
from gdm_tck.state import ScenarioContext

logger = logging.getLogger(__name__)


@then(parsers.parse('the plan of query should contain "{operator}":\n{cypher}'))
def the_plan_should_contain(
    operator: str,
    cypher: str,
    bolt_pool: BoltConnectionPool,
    scenario_ctx: ScenarioContext,
):
    """断言 EXPLAIN 执行计划包含指定操作符。

    Args:
        operator: 期望出现的操作符名称（如 NodeIndexSeek、NodeByLabelScan）。
        cypher: 用户提供的 Cypher 查询语句（docstring）。
        bolt_pool: Bolt 连接池 fixture。
        scenario_ctx: 场景上下文 fixture。
    """
    records = _execute_explain(cypher, bolt_pool, scenario_ctx)
    if _plan_contains_operator(records, operator):
        return
    raise AssertionError(
        f"Expected operator '{operator}' not found in execution plan.\n"
        f"Actual plan rows:\n{_format_plan(records)}"
    )


@then(parsers.parse('the plan of query should not contain "{operator}":\n{cypher}'))
def the_plan_should_not_contain(
    operator: str,
    cypher: str,
    bolt_pool: BoltConnectionPool,
    scenario_ctx: ScenarioContext,
):
    """断言 EXPLAIN 执行计划不包含指定操作符。

    Args:
        operator: 不期望出现的操作符名称。
        cypher: 用户提供的 Cypher 查询语句（docstring）。
        bolt_pool: Bolt 连接池 fixture。
        scenario_ctx: 场景上下文 fixture。
    """
    records = _execute_explain(cypher, bolt_pool, scenario_ctx)
    if not _plan_contains_operator(records, operator):
        return
    raise AssertionError(
        f"Operator '{operator}' should not appear in execution plan but was found.\n"
        f"Actual plan rows:\n{_format_plan(records)}"
    )


def _execute_explain(
    cypher: str,
    bolt_pool: BoltConnectionPool,
    scenario_ctx: ScenarioContext,
) -> list[dict[str, Any]]:
    """对清理后的 Cypher 添加 EXPLAIN 前缀并执行，返回结果记录列表。

    Args:
        cypher: 原始 docstring 形式的 Cypher 文本。
        bolt_pool: Bolt 连接池。
        scenario_ctx: 场景上下文，提供参数和当前数据库。

    Returns:
        EXPLAIN 查询返回的记录列表。

    Raises:
        AssertionError: EXPLAIN 执行失败时抛出，附带详细错误信息。
    """
    query = _clean_docstring(cypher)
    if not query:
        raise AssertionError("EXPLAIN query is empty")
    explain_query = f"EXPLAIN {query}"
    client = bolt_pool.primary
    result, error = client.execute_no_throw(
        explain_query, scenario_ctx.parameters, scenario_ctx.current_database
    )
    if error is not None:
        raise AssertionError(
            f"EXPLAIN query failed: {explain_query[:200]}\nError: {error}"
        )
    if result is None:
        return []
    return result.records


def _plan_contains_operator(records: list[dict[str, Any]], operator: str) -> bool:
    """在执行计划记录中搜索指定操作符字符串。

    遍历每行记录的所有字段值（递归展开 dict / list / tuple），
    将值转为字符串后做精确子串匹配。

    Args:
        records: EXPLAIN 返回的记录列表。
        operator: 目标操作符名称。

    Returns:
        若任何字段值包含 operator 字符串则返回 True。
    """
    if not operator:
        return False
    for record in records:
        for value in record.values():
            if _value_contains(value, operator):
                return True
    return False


def _value_contains(value: Any, operator: str) -> bool:
    """递归检查值（含嵌套结构）是否包含目标字符串。"""
    if value is None:
        return False
    if isinstance(value, str):
        return operator in value
    if isinstance(value, dict):
        for v in value.values():
            if _value_contains(v, operator):
                return True
        return False
    if isinstance(value, (list, tuple, set)):
        for item in value:
            if _value_contains(item, operator):
                return True
        return False
    return operator in str(value)


def _format_plan(records: list[dict[str, Any]]) -> str:
    """将执行计划记录格式化为多行字符串，便于错误信息输出。"""
    if not records:
        return "  (empty plan)"
    lines = []
    for idx, record in enumerate(records):
        lines.append(f"  [{idx}] {record}")
    return "\n".join(lines)


def _clean_docstring(text: str) -> str:
    """清理 Gherkin docstring 中的三引号标记和首尾空白。"""
    lines = text.strip().splitlines()
    cleaned = []
    for line in lines:
        if line.strip() == '"""':
            continue
        cleaned.append(line)
    return "\n".join(cleaned).strip()
