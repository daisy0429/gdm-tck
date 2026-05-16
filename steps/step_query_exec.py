"""查询执行 step definitions。

对应 Gherkin 中的 When/Given 步骤：
- executing query                (单条，延迟验证)
- executing query without error  (单条，立即失败)
- executing queries              (多条分号分隔，延迟验证)
- executing queries without error(多条分号分隔，立即失败)
- executing control query
- having executed
- test data cleared / test data exists
- drop all graph / drop all graphType
- repeating query in (N)
"""

import logging
import re
import time

from pytest_bdd import given, parsers, when

from gdm_tck.connection import BoltConnectionPool
from gdm_tck.state import ScenarioContext

logger = logging.getLogger(__name__)


@when(parsers.parse("executing query:\n{cypher}"))
def executing_query(cypher: str, bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext):
    """执行 Cypher 查询并将结果存入场景上下文。

    使用延迟验证模式：查询失败时将异常存入 scenario_ctx.last_error，
    不立即抛出，留待 Then 步骤验证。
    """
    query = _clean_docstring(cypher)
    client = bolt_pool.primary
    result, error = client.execute_no_throw(
        query, scenario_ctx.parameters, scenario_ctx.current_database
    )
    scenario_ctx.last_result = result
    scenario_ctx.last_error = error
    if error:
        logger.debug("Query execution error (deferred): %s", error)


@when(parsers.parse("executing query without error:\n{cypher}"))
def executing_query_without_error(
    cypher: str, bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext
):
    """执行单条查询，失败时立即抛出异常。"""
    query = _clean_docstring(cypher)
    client = bolt_pool.primary
    result, error = client.execute_no_throw(
        query, scenario_ctx.parameters, scenario_ctx.current_database
    )
    scenario_ctx.last_result = result
    scenario_ctx.last_error = error
    if error:
        raise AssertionError(f"Query failed: {query[:200]}\nError: {error}")


@when(parsers.parse("executing queries:\n{cypher}"))
def executing_queries(cypher: str, bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext):
    """执行多条分号分隔的查询（延迟验证模式）。

    逐条执行，保留最后一次结果和错误。
    """
    queries = _split_queries(cypher)
    client = bolt_pool.primary
    last_result = None
    last_error = None
    for q in queries:
        result, error = client.execute_no_throw(
            q, scenario_ctx.parameters, scenario_ctx.current_database
        )
        last_result = result
        if error:
            last_error = error
            logger.debug("Query error (deferred in batch): %s", error)
    scenario_ctx.last_result = last_result
    scenario_ctx.last_error = last_error


@when(parsers.parse("executing queries without error:\n{cypher}"))
def executing_queries_without_error(
    cypher: str, bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext
):
    """执行多条分号分隔的查询，任何一条失败则立即抛出。"""
    queries = _split_queries(cypher)
    client = bolt_pool.primary
    last_result = None
    for q in queries:
        result, error = client.execute_no_throw(
            q, scenario_ctx.parameters, scenario_ctx.current_database
        )
        last_result = result
        if error:
            raise AssertionError(f"Query failed in batch: {q[:200]}\nError: {error}")
    scenario_ctx.last_result = last_result
    scenario_ctx.last_error = None


@when(parsers.parse("executing control query:\n{cypher}"))
def executing_control_query(
    cypher: str, bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext
):
    """执行控制查询（与 executing query 语义相同）。"""
    executing_query(cypher, bolt_pool, scenario_ctx)


@given(parsers.parse("having executed:\n{cypher}"))
def given_having_executed(
    cypher: str, bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext
):
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


@given(parsers.parse("test data cleared: {cypher}"))
def test_data_cleared(cypher: str, bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext):
    """清除测试数据：执行给定的清理查询。"""
    client = bolt_pool.primary
    result, error = client.execute_no_throw(
        cypher.strip(), scenario_ctx.parameters, scenario_ctx.current_database
    )
    if error:
        logger.warning("Data cleanup query failed: %s", error)
    scenario_ctx.last_result = result
    scenario_ctx.last_error = error


@given(parsers.parse("test data exists:\n{cypher}"))
def test_data_exists_docstring(
    cypher: str, bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext
):
    """创建测试数据：执行 docstring 中的初始化查询（多条以分号分隔）。"""
    queries = _split_queries(cypher)
    client = bolt_pool.primary
    for q in queries:
        result, error = client.execute_no_throw(
            q, scenario_ctx.parameters, scenario_ctx.current_database
        )
        if error:
            logger.warning("Test data init query failed: %s", error)
            raise AssertionError(f"Test data setup failed: {q[:200]}\nError: {error}")
    scenario_ctx.last_result = result
    scenario_ctx.last_error = None


@given(parsers.parse("test data exists: {cypher}"))
def test_data_exists_inline(
    cypher: str, bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext
):
    """创建测试数据：执行内联的初始化查询（多条以分号分隔）。"""
    queries = [q.strip() for q in cypher.split(";") if q.strip()]
    client = bolt_pool.primary
    for q in queries:
        result, error = client.execute_no_throw(
            q, scenario_ctx.parameters, scenario_ctx.current_database
        )
        if error:
            logger.warning("Test data init query failed: %s", error)
            raise AssertionError(f"Test data setup failed: {q[:200]}\nError: {error}")
    scenario_ctx.last_result = result
    scenario_ctx.last_error = None


@when(parsers.parse("repeating query in ({count:d}):\n{cypher}"))
def repeating_query(
    count: int, cypher: str, bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext
):
    """重复执行查询 N 次，每次替换 ${n} 为当前迭代值。"""
    raw = _clean_docstring(cypher)
    statements = [s.strip() for s in raw.split(";") if s.strip()]
    client = bolt_pool.primary
    for i in range(1, count + 1):
        for stmt in statements:
            query = stmt.replace("${n}", str(i))
            result, error = client.execute_no_throw(
                query, scenario_ctx.parameters, scenario_ctx.current_database
            )
            if error:
                raise AssertionError(
                    f"Repeating query failed at iteration {i}: {query[:200]}\nError: {error}"
                )
    scenario_ctx.last_result = result
    scenario_ctx.last_error = None


@when(
    parsers.re(
        r'executing query by USER\["(?P<user>[^"]+)"\]-\[(?P<idx>\d+)\]-DB\["(?P<db>[^"]+)"\] without error:\n(?P<cypher>.+)',
        re.DOTALL,
    )
)
def executing_query_by_user_without_error(
    user: str,
    idx: str,
    db: str,
    cypher: str,
    bolt_pool: BoltConnectionPool,
    scenario_ctx: ScenarioContext,
):
    """以指定用户身份在指定数据库上执行查询（失败立即抛出）。"""
    query = _clean_docstring(cypher)
    client = _get_user_client(bolt_pool, scenario_ctx, user, db)
    result, error = client.execute_no_throw(query, scenario_ctx.parameters, db)
    scenario_ctx.last_result = result
    scenario_ctx.last_error = error
    if error:
        raise AssertionError(
            f"Query by user '{user}' on DB '{db}' failed: {query[:200]}\nError: {error}"
        )


@when("sleep ({seconds:d})")
def sleep_step(seconds: int):
    """等待指定秒数。"""
    time.sleep(seconds)


def _get_user_client(
    bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext, username: str, database: str
):
    """获取或创建指定用户的客户端连接。"""
    if username not in scenario_ctx.user_clients:
        client = bolt_pool.create_user_client(username, "", database)
        scenario_ctx.user_clients[username] = [client]
        return client
    clients = scenario_ctx.user_clients[username]
    if clients:
        return clients[0]
    client = bolt_pool.create_user_client(username, "", database)
    scenario_ctx.user_clients[username] = [client]
    return client


def _split_queries(cypher: str) -> list[str]:
    """清理 docstring 并按分号分割为多条查询。"""
    text = _clean_docstring(cypher)
    return [q.strip() for q in text.split(";") if q.strip()]


def _clean_docstring(text: str) -> str:
    """清理 Gherkin docstring 中的多余标记。

    移除三引号标记和多余空白行。
    """
    lines = text.strip().splitlines()
    cleaned = []
    for line in lines:
        stripped = line.strip()
        if stripped == '"""':
            continue
        cleaned.append(line)
    return "\n".join(cleaned).strip()
