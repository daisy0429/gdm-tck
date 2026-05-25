"""结果断言 step definitions。

对应 Gherkin 中的 Then 步骤：
- the result should be, in any order
- the result should be, in order
- the result should be empty
- the result should not be empty
- the result should be (scalar docstring)
- the result count should be [N]
- the result path node count should be N
- the result should contain (bare)
- the error should be contain / the error should contain
- the column count should match the following list
"""

import re

from pytest_bdd import then, parsers

from gdm_tck.result import (
    assert_result_empty,
    assert_result_equal_any_order,
    assert_result_equal_in_order,
    assert_result_contains,
)
from gdm_tck.state import ScenarioContext


@then("the result should be empty")
def the_result_should_be_empty(scenario_ctx: ScenarioContext):
    """断言查询结果为空集。"""
    if scenario_ctx.has_error:
        raise AssertionError(f"Expected empty result but query failed: {scenario_ctx.last_error}")
    assert_result_empty(scenario_ctx.result_records)


@then("the result should not be empty")
def the_result_should_not_be_empty(scenario_ctx: ScenarioContext):
    """断言查询结果非空。"""
    if scenario_ctx.has_error:
        raise AssertionError(
            f"Expected non-empty result but query failed: {scenario_ctx.last_error}"
        )
    if len(scenario_ctx.result_records) == 0:
        raise AssertionError("Expected non-empty result but got 0 rows")


@then(parsers.parse("the result should be:\n{value}"))
def the_result_should_be_scalar(value: str, scenario_ctx: ScenarioContext):
    """断言结果为单个标量值（docstring 模式）。"""
    if scenario_ctx.has_error:
        raise AssertionError(f"Expected result but query failed: {scenario_ctx.last_error}")
    expected = value.strip().strip('"""').strip()
    records = scenario_ctx.result_records
    if not records:
        raise AssertionError(f"Expected result '{expected}' but got empty result set")
    actual_val = list(records[0].values())[0]
    actual_str = str(actual_val)
    if actual_str != expected:
        raise AssertionError(f"Result mismatch:\n  Expected: {expected}\n  Actual:   {actual_str}")


@then(parsers.parse("the result should be, in any order:\n{table}"))
@then(parsers.parse("the result should be (ignoring element order for lists):\n{table}"))
def the_result_should_be_in_any_order(table: str, scenario_ctx: ScenarioContext):
    """断言结果集与期望匹配（忽略行顺序）。"""
    if scenario_ctx.has_error:
        raise AssertionError(f"Expected results but query failed: {scenario_ctx.last_error}")
    header, rows = _parse_gherkin_table(table)
    assert_result_equal_any_order(
        scenario_ctx.result_records,
        scenario_ctx.result_keys,
        header,
        rows,
    )


@then(parsers.parse("the result should be, in order:\n{table}"))
def the_result_should_be_in_order(table: str, scenario_ctx: ScenarioContext):
    """断言结果集与期望匹配（保持行顺序）。"""
    if scenario_ctx.has_error:
        raise AssertionError(f"Expected results but query failed: {scenario_ctx.last_error}")
    header, rows = _parse_gherkin_table(table)
    assert_result_equal_in_order(
        scenario_ctx.result_records,
        scenario_ctx.result_keys,
        header,
        rows,
    )


@then(parsers.parse("the result should contain, in any order:\n{table}"))
@then(parsers.parse("the result should contain:\n{table}"))
def the_result_should_contain(table: str, scenario_ctx: ScenarioContext):
    """断言结果集包含所有期望行。"""
    if scenario_ctx.has_error:
        raise AssertionError(f"Expected results but query failed: {scenario_ctx.last_error}")
    header, rows = _parse_gherkin_table(table)
    assert_result_contains(
        scenario_ctx.result_records,
        scenario_ctx.result_keys,
        header,
        rows,
    )


@then(parsers.re(r"the result count should be \[(?P<count>\d+)\]"))
def the_result_count_should_be(count: str, scenario_ctx: ScenarioContext):
    """断言结果行数等于指定值。"""
    if scenario_ctx.has_error:
        raise AssertionError(f"Expected result count but query failed: {scenario_ctx.last_error}")
    expected = int(count)
    actual = len(scenario_ctx.result_records)
    if actual != expected:
        raise AssertionError(f"Result count mismatch: expected [{expected}], got [{actual}]")


@then(parsers.parse("the result path node count should be {count:d}"))
def the_result_path_node_count(count: int, scenario_ctx: ScenarioContext):
    """断言结果路径中的节点数量。"""
    if scenario_ctx.has_error:
        raise AssertionError(
            f"Expected path node count but query failed: {scenario_ctx.last_error}"
        )
    records = scenario_ctx.result_records
    if not records:
        raise AssertionError("Expected path result but got empty result set")
    path_val = list(records[0].values())[0]
    node_count = len(path_val.nodes) if hasattr(path_val, "nodes") else 0
    if node_count != count:
        raise AssertionError(f"Path node count mismatch: expected {count}, got {node_count}")


@then(parsers.parse("the column count should match the following list:\n{table}"))
def the_column_count_should_match(table: str, scenario_ctx: ScenarioContext):
    """断言结果列数与期望列表匹配。"""
    if scenario_ctx.has_error:
        raise AssertionError(f"Expected column count but query failed: {scenario_ctx.last_error}")
    lines = [l.strip() for l in table.strip().splitlines() if l.strip().startswith("|")]
    expected_cols = []
    for line in lines:
        cells = [c.strip() for c in line.split("|")[1:-1]]
        expected_cols.extend(cells)
    actual_keys = scenario_ctx.result_keys
    if len(actual_keys) != len(expected_cols):
        raise AssertionError(
            f"Column count mismatch: expected {len(expected_cols)} ({expected_cols}), "
            f"got {len(actual_keys)} ({actual_keys})"
        )


@then(parsers.parse("the error should be contain:\n{text}"))
@then(parsers.parse("the error should contain:\n{text}"))
def the_error_should_contain(text: str, scenario_ctx: ScenarioContext):
    """断言错误消息包含指定文本。"""
    if not scenario_ctx.has_error:
        raise AssertionError("Expected an error but query succeeded")
    expected = text.strip().strip('"""').strip()
    error_msg = str(scenario_ctx.last_error)
    if expected not in error_msg:
        raise AssertionError(
            f"Error message does not contain '{expected}'\nActual error: {error_msg}"
        )


def _parse_gherkin_table(table_text: str) -> tuple[list[str], list[list[str]]]:
    """解析 Gherkin 数据表格文本为 header 和 rows。

    表格格式：
    | col1 | col2 |
    | val1 | val2 |

    Args:
        table_text: Gherkin 表格文本。

    Returns:
        (header, rows): 列名列表和数据行列表。
    """
    lines = [
        line.strip()
        for line in table_text.strip().splitlines()
        if line.strip() and line.strip().startswith("|")
    ]
    if not lines:
        return [], []

    def parse_row(line: str) -> list[str]:
        """解析单行表格数据。"""
        cells = line.split("|")
        # 去掉首尾空单元格（由 | 开头和结尾产生）
        return [cell.strip() for cell in cells[1:-1]]

    header = parse_row(lines[0])
    rows = [parse_row(line) for line in lines[1:]]
    return header, rows
