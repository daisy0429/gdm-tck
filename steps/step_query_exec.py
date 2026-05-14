"""查询执行 step definitions。

对应 Gherkin 中的 When 步骤：
- executing query
- executing control query
- having executed
"""

import logging

from pytest_bdd import given, parsers, when

from gdm_tck.connection import BoltConnectionPool
from gdm_tck.state import ScenarioContext

logger = logging.getLogger(__name__)


@when(parsers.parse("executing query:\n{cypher}"))
def executing_query(cypher: str, bolt_pool: BoltConnectionPool,
                    scenario_ctx: ScenarioContext):
    """执行 Cypher 查询并将结果存入场景上下文。

    使用延迟验证模式：查询失败时将异常存入 scenario_ctx.last_error，
    不立即抛出，留待 Then 步骤验证。
    """
    # 清理 docstring 标记
    query = _clean_docstring(cypher)
    client = bolt_pool.primary
    result, error = client.execute_no_throw(
        query, scenario_ctx.parameters, scenario_ctx.current_database
    )
    scenario_ctx.last_result = result
    scenario_ctx.last_error = error
    if error:
        logger.debug("Query execution error (deferred): %s", error)


@when(parsers.parse("executing control query:\n{cypher}"))
def executing_control_query(cypher: str, bolt_pool: BoltConnectionPool,
                            scenario_ctx: ScenarioContext):
    """执行控制查询（与 executing query 语义相同）。"""
    executing_query(cypher, bolt_pool, scenario_ctx)


@given(parsers.parse("having executed:\n{cypher}"))
def given_having_executed(cypher: str, bolt_pool: BoltConnectionPool,
                          scenario_ctx: ScenarioContext):
    """Given 步骤中的前置查询执行。

    与 When 不同，这里执行的查询是场景的前置条件，
    失败时仍存入 last_error 但通常不期望失败。
    """
    query = _clean_docstring(cypher)
    client = bolt_pool.primary
    result, error = client.execute_no_throw(
        query, scenario_ctx.parameters, scenario_ctx.current_database
    )
    scenario_ctx.last_result = result
    scenario_ctx.last_error = error


def _clean_docstring(text: str) -> str:
    """清理 Gherkin docstring 中的多余标记。

    移除三引号标记和多余空白行。
    """
    lines = text.strip().splitlines()
    # 移除可能的三引号行
    cleaned = []
    for line in lines:
        stripped = line.strip()
        if stripped == '"""':
            continue
        cleaned.append(line)
    return "\n".join(cleaned).strip()
