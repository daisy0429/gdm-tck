"""Schema 断言 step definitions。

对应 Gherkin 中的 Then 步骤：
- the index "{name}" should exist
- the index "{name}" should not exist

通过 SHOW INDEXES YIELD name 获取当前数据库中的所有索引名，
据此校验目标索引是否存在/不存在。
"""

from pytest_bdd import then, parsers

from gdm_tck.connection import BoltConnectionPool
from gdm_tck.state import ScenarioContext


def _list_index_names(
    bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext
) -> list[str]:
    """查询当前数据库的所有索引名称列表。

    通过 SHOW INDEXES YIELD name 获取索引清单。
    若查询失败则抛出 AssertionError，避免静默放过断言。
    """
    client = bolt_pool.primary
    result, error = client.execute_no_throw(
        "SHOW INDEXES YIELD name",
        scenario_ctx.parameters,
        scenario_ctx.current_database,
    )
    if error is not None:
        raise AssertionError(f"Failed to list indexes via SHOW INDEXES: {error}")
    if result is None:
        return []
    names: list[str] = []
    for record in result.records:
        value = record.get("name")
        if value is not None:
            names.append(str(value))
    return names


@then(parsers.parse('the index "{name}" should exist'))
def the_index_should_exist(
    name: str, bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext
):
    """断言指定名称的索引存在于当前数据库。"""
    names = _list_index_names(bolt_pool, scenario_ctx)
    if name not in names:
        raise AssertionError(
            f"Expected index '{name}' to exist, but not found. "
            f"Current indexes: {names}"
        )


@then(parsers.parse('the index "{name}" should not exist'))
def the_index_should_not_exist(
    name: str, bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext
):
    """断言指定名称的索引在当前数据库不存在。"""
    names = _list_index_names(bolt_pool, scenario_ctx)
    if name in names:
        raise AssertionError(
            f"Expected index '{name}' to not exist, but it was found. "
            f"Current indexes: {names}"
        )
