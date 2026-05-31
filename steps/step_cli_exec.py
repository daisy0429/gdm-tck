"""gdm-cli 工具 step definitions。

对应 Gherkin 中的 When/Then 步骤：
- executing gdm-cli with "-e" flag
- executing gdm-cli with options
- executing gdm-cli in batch mode
- executing gdm-cli with format
- CLI exit code assertions
- CLI output assertions
- Bolt query verification steps
"""

from __future__ import annotations

import logging

from pytest_bdd import given, parsers, then, when

from gdm_tck.cli.cli_runner import CliRunner
from gdm_tck.connection import BoltConnectionPool
from gdm_tck.state import ScenarioContext

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Given Steps
# ---------------------------------------------------------------------------

@given("an empty graph for CLI test")
def an_empty_graph_for_cli(bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext):
    """清空图数据，确保 CLI 测试从完全空图开始。

    与 step_graph_init.py 中的 an_empty_graph 语义相同，
    但独立注册以避免步骤名称冲突。
    """
    client = bolt_pool.primary
    # 删除所有约束
    try:
        result = client.execute("SHOW CONSTRAINTS", database=scenario_ctx.current_database)
        for record in result.records:
            name = record.get("name", "")
            if name:
                client.execute(
                    f"DROP CONSTRAINT {name} IF EXISTS",
                    database=scenario_ctx.current_database,
                )
    except Exception as e:
        logger.debug("SHOW CONSTRAINTS not supported or failed: %s", e)

    # 删除所有索引
    try:
        result = client.execute("SHOW INDEXES", database=scenario_ctx.current_database)
        for record in result.records:
            owning = record.get("owningConstraint")
            if owning:
                continue
            idx_type = (record.get("type") or "").upper()
            if idx_type == "LOOKUP":
                continue
            name = record.get("name", "")
            if name:
                client.execute(
                    f"DROP INDEX {name} IF EXISTS",
                    database=scenario_ctx.current_database,
                )
    except Exception as e:
        logger.debug("SHOW INDEXES not supported or failed: %s", e)

    # 清除所有节点和关系
    client.execute("MATCH (n) DETACH DELETE n", database=scenario_ctx.current_database)
    logger.debug("Graph fully cleared for CLI test")


@given(parsers.parse('test data is loaded into graph "{graph}"'))
def test_data_loaded(graph: str, bolt_pool: BoltConnectionPool):
    """加载测试数据到指定图。

    当前使用 quickstart 数据创建基础测试数据。
    """
    client = bolt_pool.primary
    # 创建测试数据
    cypher = """
    CREATE (:Person {id: 1, name: 'Alice', age: 30, city: 'Beijing'}),
           (:Person {id: 2, name: 'Bob', age: 25, city: 'Shanghai'}),
           (:Person {id: 3, name: 'Charlie', age: 35, city: 'Guangzhou'})
    """
    client.execute(cypher, database=graph)
    logger.debug("Test data loaded into graph '%s'", graph)


# ---------------------------------------------------------------------------
# When Steps - gdm-cli
# ---------------------------------------------------------------------------

@when(parsers.parse('executing gdm-cli with "-e" flag:\n{cypher}'))
def executing_cli_e(cypher: str, cli_runner: CliRunner, scenario_ctx: ScenarioContext):
    """执行 gdm-cli -e 命令（使用默认 graph）。"""
    query = _clean_docstring(cypher)
    result = cli_runner.execute(query, graph=scenario_ctx.current_database)
    scenario_ctx.last_command_result = result
    logger.debug("gdm-cli -e exited with code %d", result.exit_code)


@when(parsers.parse('executing gdm-cli with "-e" flag on graph "{graph}":\n{cypher}'))
def executing_cli_e_with_graph(
    graph: str, cypher: str, cli_runner: CliRunner, scenario_ctx: ScenarioContext
):
    """执行指定 graph 的 gdm-cli -e 命令。"""
    query = _clean_docstring(cypher)
    result = cli_runner.execute(query, graph=graph)
    scenario_ctx.last_command_result = result
    logger.debug("gdm-cli -e on graph '%s' exited with code %d", graph, result.exit_code)


@when(parsers.parse('executing gdm-cli with options "{options}":\n{cypher}'))
def executing_cli_with_options(
    options: str, cypher: str, cli_runner: CliRunner, scenario_ctx: ScenarioContext
):
    """执行带额外选项的 gdm-cli 命令。"""
    query = _clean_docstring(cypher)
    args = options.split()
    args.extend(["-e", query])
    result = cli_runner.run_raw(args)
    scenario_ctx.last_command_result = result
    logger.debug("gdm-cli with options exited with code %d", result.exit_code)


@when(parsers.parse("executing gdm-cli in batch mode:\n{input}"))
def executing_cli_batch(input: str, cli_runner: CliRunner, scenario_ctx: ScenarioContext):
    """执行 gdm-cli --batch 命令。"""
    data = _clean_docstring(input)
    result = cli_runner.batch(data)
    scenario_ctx.last_command_result = result
    logger.debug("gdm-cli batch exited with code %d", result.exit_code)


@when(parsers.parse('executing gdm-cli with format "{format}":\n{cypher}'))
def executing_cli_with_format(
    format: str, cypher: str, cli_runner: CliRunner, scenario_ctx: ScenarioContext  # noqa: A002
):
    """执行指定输出格式的 gdm-cli 命令。"""
    query = _clean_docstring(cypher)
    result = cli_runner.execute(query, format=format)
    scenario_ctx.last_command_result = result
    logger.debug("gdm-cli with format exited with code %d", result.exit_code)


# ---------------------------------------------------------------------------
# Then Steps - CLI Assertions
# ---------------------------------------------------------------------------

@then(parsers.parse("the CLI exit code should be {code:d}"))
def cli_exit_code(code: int, scenario_ctx: ScenarioContext):
    """断言 CLI 命令退出码。"""
    result = scenario_ctx.last_command_result
    if result is None:
        raise AssertionError("No CLI command result available")

    if result.exit_code != code:
        raise AssertionError(
            f"Exit code mismatch: expected {code}, got {result.exit_code}\n"
            f"Stderr: {result.stderr[:500]}"
        )


@then(parsers.parse('the CLI output should contain "{text}"'))
def cli_output_contains(text: str, scenario_ctx: ScenarioContext):
    """断言 CLI 标准输出包含指定文本。"""
    result = scenario_ctx.last_command_result
    if result is None:
        raise AssertionError("No CLI command result available")

    if text not in result.stdout:
        raise AssertionError(
            f"Output does not contain '{text}'\n"
            f"Stdout: {result.stdout[:500]}"
        )


@then(parsers.parse('the CLI error output should contain "{text}"'))
def cli_error_contains(text: str, scenario_ctx: ScenarioContext):
    """断言 CLI 标准错误输出包含指定文本。"""
    result = scenario_ctx.last_command_result
    if result is None:
        raise AssertionError("No CLI command result available")

    if text not in result.stderr:
        raise AssertionError(
            f"Error output does not contain '{text}'\n"
            f"Stderr: {result.stderr[:500]}"
        )


# ---------------------------------------------------------------------------
# Then Steps - Bolt Verification
# ---------------------------------------------------------------------------

@when(parsers.parse("verifying via Bolt the query:\n{cypher}"))
def verifying_via_bolt(cypher: str, bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext):
    """通过 Bolt 执行验证查询，结果存入场景上下文。"""
    query = _clean_docstring(cypher)
    client = bolt_pool.primary
    result, error = client.execute_no_throw(query, scenario_ctx.parameters, scenario_ctx.current_database)
    scenario_ctx.last_result = result
    scenario_ctx.last_error = error
    if error:
        logger.debug("Bolt verification query error (deferred): %s", error)


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
