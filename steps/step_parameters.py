"""参数 step definitions。

对应 Gherkin 中的 Given 步骤：
- parameters are
"""

from pytest_bdd import given, parsers

from gdm_tck.result.parser import parse_tck_value
from gdm_tck.state import ScenarioContext


@given(parsers.parse("parameters are:\n{table}"))
def parameters_are(table: str, scenario_ctx: ScenarioContext):
    """设置当前场景的查询参数。

    表格格式：
    | name  | value |
    | param | 42    |
    """
    rows = _parse_param_table(table)
    for name, value_text in rows:
        scenario_ctx.parameters[name] = parse_tck_value(value_text)


def _parse_param_table(table_text: str) -> list[tuple[str, str]]:
    """解析参数表格，返回 (name, value) 对列表。

    跳过表头行（如果有 'name' 列）。
    """
    pairs = []
    for line in table_text.strip().splitlines():
        line = line.strip()
        if not line or not line.startswith("|"):
            continue
        cells = [cell.strip() for cell in line.split("|")[1:-1]]
        if len(cells) >= 2:
            # 跳过表头
            if cells[0].lower() == "name" and cells[1].lower() == "value":
                continue
            pairs.append((cells[0], cells[1]))
    return pairs
