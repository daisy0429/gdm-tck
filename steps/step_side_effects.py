"""副作用断言 step definitions。

对应 Gherkin 中的 And 步骤：
- the side effects should be
- no side effects
"""

from pytest_bdd import then, parsers

from gdm_tck.result.side_effects import (
    assert_no_side_effects,
    assert_side_effects,
    parse_side_effects_table,
)
from gdm_tck.state import ScenarioContext


@then(parsers.parse("the side effects should be:\n{table}"))
def the_side_effects_should_be(table: str, scenario_ctx: ScenarioContext):
    """断言查询的副作用与期望匹配。

    表格格式：
    | +nodes | 1 |
    | +relationships | 2 |
    """
    if scenario_ctx.has_error:
        raise AssertionError(
            f"Cannot check side effects: query failed with {scenario_ctx.last_error}"
        )
    rows = _parse_simple_table(table)
    expected = parse_side_effects_table(rows)
    summary = scenario_ctx.last_result.summary if scenario_ctx.last_result else None
    assert_side_effects(summary, expected)


@then("no side effects")
def no_side_effects(scenario_ctx: ScenarioContext):
    """断言查询没有产生任何副作用。"""
    if scenario_ctx.has_error:
        return  # 如果有错误，不检查副作用
    summary = scenario_ctx.last_result.summary if scenario_ctx.last_result else None
    assert_no_side_effects(summary)


def _parse_simple_table(table_text: str) -> list[list[str]]:
    """解析简单的两列 Gherkin 表格。"""
    rows = []
    for line in table_text.strip().splitlines():
        line = line.strip()
        if not line or not line.startswith("|"):
            continue
        cells = [cell.strip() for cell in line.split("|")[1:-1]]
        if cells:
            rows.append(cells)
    return rows
