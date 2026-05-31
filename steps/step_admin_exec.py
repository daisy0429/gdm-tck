"""gdm-admin 工具 step definitions。

对应 Gherkin 中的 When/Then 步骤：
- executing gdm-admin import with manifest
- executing gdm-admin import dry-run with manifest
- executing gdm-admin command with args
- import summary assertions
- graph data verification via Bolt
"""

from __future__ import annotations

import logging

from pytest_bdd import parsers, then, when

from gdm_tck.cli.admin_runner import AdminRunner
from gdm_tck.cli.output_parser import extract_import_summary
from gdm_tck.connection import BoltConnectionPool
from gdm_tck.state import ScenarioContext

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# When Steps
# ---------------------------------------------------------------------------

@when(parsers.parse('executing gdm-admin command "{command}" with args "{args}"'))
def executing_admin_command(
    command: str,
    args: str,
    admin_runner: AdminRunner,
    scenario_ctx: ScenarioContext,
):
    """执行通用 gdm-admin 命令。

    预留的通用步骤，支持未来扩展 catalog、status 等子命令。
    """
    args_list = args.split() if args else []
    result = admin_runner.run_raw(command, args_list)
    scenario_ctx.last_command_result = result
    logger.debug("Admin command '%s' exited with code %d", command, result.exit_code)


@when(parsers.parse('executing gdm-admin import with manifest "{manifest}"'))
def executing_admin_import(
    manifest: str,
    admin_runner: AdminRunner,
    scenario_ctx: ScenarioContext,
):
    """执行 gdm-admin import 命令。"""
    result = admin_runner.import_data(manifest)
    scenario_ctx.last_command_result = result
    logger.debug("Import command exited with code %d", result.exit_code)


@when(parsers.parse('executing gdm-admin import dry-run with manifest "{manifest}"'))
def executing_admin_import_dry_run(
    manifest: str,
    admin_runner: AdminRunner,
    scenario_ctx: ScenarioContext,
):
    """执行 gdm-admin import --dry-run 命令。"""
    result = admin_runner.import_data(manifest, dry_run=True)
    scenario_ctx.last_command_result = result
    logger.debug("Import dry-run command exited with code %d", result.exit_code)


# ---------------------------------------------------------------------------
# Then Steps - Import Summary
# ---------------------------------------------------------------------------

@then(parsers.parse('the import summary should show status "{status}"'))
def import_summary_status(status: str, scenario_ctx: ScenarioContext):
    """断言导入报告状态。"""
    result = scenario_ctx.last_command_result
    if result is None:
        raise AssertionError("No import command result available")

    summary = extract_import_summary(result.stdout)
    actual_status = summary.get("status")
    expected = status.upper()

    if actual_status != expected:
        raise AssertionError(
            f"Import status mismatch: expected '{expected}', got '{actual_status}'\n"
            f"Stdout: {result.stdout[:500]}"
        )


@then(parsers.parse("the import summary should show {n:d} vertices imported"))
def import_summary_vertices(n: int, scenario_ctx: ScenarioContext):
    """断言导入的顶点数。"""
    result = scenario_ctx.last_command_result
    if result is None:
        raise AssertionError("No import command result available")

    summary = extract_import_summary(result.stdout)
    actual = summary.get("vertices_imported", 0)

    if actual != n:
        raise AssertionError(
            f"Vertex count mismatch: expected {n}, got {actual}\n"
            f"Stdout: {result.stdout[:500]}"
        )


@then(parsers.parse("the import summary should show {n:d} edges imported"))
def import_summary_edges(n: int, scenario_ctx: ScenarioContext):
    """断言导入的边数。"""
    result = scenario_ctx.last_command_result
    if result is None:
        raise AssertionError("No import command result available")

    summary = extract_import_summary(result.stdout)
    actual = summary.get("edges_imported", 0)

    if actual != n:
        raise AssertionError(
            f"Edge count mismatch: expected {n}, got {actual}\n"
            f"Stdout: {result.stdout[:500]}"
        )


@when(parsers.parse('executing gdm-admin import with manifest "{manifest}" and args "{args}"'))
def executing_admin_import_with_args(
    manifest: str,
    args: str,
    admin_runner: AdminRunner,
    scenario_ctx: ScenarioContext,
):
    """执行带自定义参数的 gdm-admin import 命令。

    Args:
        manifest: manifest 文件路径（相对于 testdata/import/）。
        args: 空格分隔的额外命令行参数。
        admin_runner: AdminRunner 实例。
        scenario_ctx: 场景上下文。
    """
    args_list = args.split() if args else []
    result = admin_runner.import_data_with_args(manifest, args_list)
    scenario_ctx.last_command_result = result
    logger.debug("Import command with args exited with code %d", result.exit_code)


@then("the CLI exit code should be 0")
def cli_exit_code_zero(scenario_ctx: ScenarioContext):
    """断言 CLI 命令退出码为 0。"""
    result = scenario_ctx.last_command_result
    if result is None:
        raise AssertionError("No command result available")

    if result.exit_code != 0:
        raise AssertionError(
            f"Expected exit code 0, got {result.exit_code}\n"
            f"Stdout: {result.stdout[:500]}\n"
            f"Stderr: {result.stderr[:500]}"
        )


@then("the CLI exit code should not be 0")
def cli_exit_code_not_zero(scenario_ctx: ScenarioContext):
    """断言 CLI 命令退出码不为 0。"""
    result = scenario_ctx.last_command_result
    if result is None:
        raise AssertionError("No command result available")

    if result.exit_code == 0:
        raise AssertionError(
            f"Expected non-zero exit code, got 0\n"
            f"Stdout: {result.stdout[:500]}"
        )


@then(parsers.parse("the CLI stderr should contain '{substring}'"))
def cli_stderr_should_contain(substring: str, scenario_ctx: ScenarioContext):
    """断言 CLI 命令的 stderr 中包含指定文本。"""
    result = scenario_ctx.last_command_result
    if result is None:
        raise AssertionError("No command result available")

    combined = result.stderr + result.stdout
    if substring not in combined:
        raise AssertionError(
            f"Expected stderr+stdout to contain '{substring}'\n"
            f"Stderr: {result.stderr[:500]}\n"
            f"Stdout: {result.stdout[:500]}"
        )


@then(parsers.parse("the import summary should show {n:d} rows skipped"))
def import_summary_rows_skipped(n: int, scenario_ctx: ScenarioContext):
    """断言导入摘要中跳过的行数。"""
    result = scenario_ctx.last_command_result
    if result is None:
        raise AssertionError("No import command result available")

    summary = extract_import_summary(result.stdout)
    actual = summary.get("rows_skipped", 0)

    if actual != n:
        raise AssertionError(
            f"Skipped rows count mismatch: expected {n}, got {actual}\n"
            f"Stdout: {result.stdout[:500]}"
        )


@then(parsers.parse("the import summary should show {n:d} rows errored"))
def import_summary_rows_errored(n: int, scenario_ctx: ScenarioContext):
    """断言导入摘要中错误的行数。"""
    result = scenario_ctx.last_command_result
    if result is None:
        raise AssertionError("No import command result available")

    summary = extract_import_summary(result.stdout)
    actual = summary.get("rows_errored", 0)

    if actual != n:
        raise AssertionError(
            f"Errored rows count mismatch: expected {n}, got {actual}\n"
            f"Stdout: {result.stdout[:500]}"
        )


# ---------------------------------------------------------------------------
# Then Steps - Graph Data Verification via Bolt
# ---------------------------------------------------------------------------
# 注意：图库内数据校验使用现有的 executing query + the result should be 步骤
# 参见 step_query_exec.py 和 step_result_assert.py
