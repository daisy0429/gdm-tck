"""结果断言 step definitions。

对应 Gherkin 中的 Then 步骤：
- the result should be, in any order
- the result should be, in order
- the result should be empty
"""

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
        raise AssertionError(
            f"Expected empty result but query failed: {scenario_ctx.last_error}"
        )
    assert_result_empty(scenario_ctx.result_records)


@then(parsers.parse("the result should be, in any order:\n{table}"))
def the_result_should_be_in_any_order(table: str, scenario_ctx: ScenarioContext):
    """断言结果集与期望匹配（忽略行顺序）。"""
    if scenario_ctx.has_error:
        raise AssertionError(
            f"Expected results but query failed: {scenario_ctx.last_error}"
        )
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
        raise AssertionError(
            f"Expected results but query failed: {scenario_ctx.last_error}"
        )
    header, rows = _parse_gherkin_table(table)
    assert_result_equal_in_order(
        scenario_ctx.result_records,
        scenario_ctx.result_keys,
        header,
        rows,
    )


@then(parsers.parse("the result should contain, in any order:\n{table}"))
def the_result_should_contain(table: str, scenario_ctx: ScenarioContext):
    """断言结果集包含所有期望行。"""
    if scenario_ctx.has_error:
        raise AssertionError(
            f"Expected results but query failed: {scenario_ctx.last_error}"
        )
    header, rows = _parse_gherkin_table(table)
    assert_result_contains(
        scenario_ctx.result_records,
        scenario_ctx.result_keys,
        header,
        rows,
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
    lines = [line.strip() for line in table_text.strip().splitlines()
             if line.strip() and line.strip().startswith("|")]
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
