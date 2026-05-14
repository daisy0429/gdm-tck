"""图初始化 step definitions。

对应 Gherkin 中的 Given 步骤：
- an empty graph
- any graph
- an load graph
"""

import logging
import re

from pytest_bdd import given, parsers

from gdm_tck.connection import BoltConnectionPool
from gdm_tck.state import ScenarioContext

logger = logging.getLogger(__name__)


@given("an empty graph")
def an_empty_graph(bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext):
    """清空图数据，确保测试从空图开始。

    执行 MATCH (n) DETACH DELETE n 清除所有节点和关系。
    """
    client = bolt_pool.primary
    client.execute("MATCH (n) DETACH DELETE n", database=scenario_ctx.current_database)
    logger.debug("Graph cleared for empty graph scenario")


@given("any graph")
def any_graph():
    """标记测试不依赖特定图状态，无需初始化操作。"""
    pass


@given(parsers.parse('having executed:\n"""\n{cypher}\n"""'))
def having_executed(cypher: str, bolt_pool: BoltConnectionPool,
                    scenario_ctx: ScenarioContext):
    """在场景开始前执行初始化查询。

    用于 Given 步骤中设置前置数据。
    """
    client = bolt_pool.primary
    result, error = client.execute_no_throw(
        cypher, scenario_ctx.parameters, scenario_ctx.current_database
    )
    if error:
        logger.warning("Pre-execution query failed: %s", error)


@given(parsers.re(r"there exists a procedure (?P<proc_signature>.+)", re.DOTALL))
def there_exists_a_procedure(proc_signature: str):
    """声明存在一个测试用存储过程。

    openCypher TCK 假设存在 test.* 系列 mock procedure。
    GDM 目前不支持自定义存储过程，此步骤作为 noop 记录。
    测试中 CALL 语句可能因 procedure 不存在而失败，属于已知不兼容项。
    """
    logger.info("TCK procedure declaration (not supported in GDM): %s",
                proc_signature.split("::")[0].strip())
