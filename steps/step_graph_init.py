"""图初始化 step definitions。

对应 Gherkin 中的 Given/When/Then 步骤：
- an empty graph
- any graph
- an load graph
- an already exist graph
- drop all graph / drop all graphType
"""

import logging
import re

from pytest_bdd import given, parsers, when, then

from gdm_tck.connection import BoltConnectionPool
from gdm_tck.state import ScenarioContext

logger = logging.getLogger(__name__)


@given("an empty graph")
def an_empty_graph(bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext):
    """清空图数据、约束和索引，确保测试从完全空图开始。

    依次执行：
    1. 删除所有约束（约束删除后从属索引自动清除）
    2. 删除所有非从属索引（排除 LOOKUP 等系统索引）
    3. 清除所有节点和关系
    """
    client = bolt_pool.primary
    _drop_all_constraints(client, scenario_ctx.current_database)
    _drop_all_indexes(client, scenario_ctx.current_database)
    client.execute("MATCH (n) DETACH DELETE n", database=scenario_ctx.current_database)
    logger.debug("Graph fully cleared (data + constraints + indexes)")


@given("any graph")
def any_graph():
    """标记测试不依赖特定图状态，无需初始化操作。"""
    pass


@given(parsers.parse('having executed:\n"""\n{cypher}\n"""'))
def having_executed(cypher: str, bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext):
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
    logger.info(
        "TCK procedure declaration (not supported in GDM): %s",
        proc_signature.split("::")[0].strip(),
    )


@given(parsers.parse("an already exist graph:\n{name}"))
def an_already_exist_graph(name: str, bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext):
    """断言指定名称的图已存在（noop 标记步骤）。

    在 GDM 中此步骤仅记录图名，不做额外操作，
    因为图已在之前步骤中创建。
    """
    graph_name = name.strip().strip('"""').strip()
    logger.debug("Asserting graph '%s' already exists (noop)", graph_name)


@given("drop all graph")
@when("drop all graph")
@then("drop all graph")
def drop_all_graph(bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext):
    """删除所有非系统图。

    查询 SHOW GRAPH，逐一删除非 default/sys/system 图。
    对于 offline 图先设为 online 再删除。
    """
    client = bolt_pool.primary
    try:
        show_result = client.execute("SHOW GRAPH", database=scenario_ctx.current_database)
    except Exception as e:
        logger.warning("SHOW GRAPH failed: %s", e)
        return

    protected = {"default", "sys", "system"}
    for record in show_result.records:
        graph_name = str(record.get("name", ""))
        if graph_name.lower() in protected:
            continue
        status = str(record.get("status", ""))
        if status.lower() == "offline":
            try:
                client.execute(
                    f"ALTER GRAPH {graph_name} ONLINE",
                    database=scenario_ctx.current_database,
                )
            except Exception as e:
                logger.warning("Failed to set graph %s online: %s", graph_name, e)
        try:
            client.execute(
                f"DROP GRAPH {graph_name}",
                database=scenario_ctx.current_database,
            )
            logger.debug("Dropped graph: %s", graph_name)
        except Exception as e:
            logger.warning("Failed to drop graph %s: %s", graph_name, e)


@given("drop all graphType")
@when("drop all graphType")
@then("drop all graphType")
def drop_all_graph_type(bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext):
    """删除所有图类型。"""
    client = bolt_pool.primary
    try:
        show_result = client.execute("SHOW GRAPH TYPE", database=scenario_ctx.current_database)
    except Exception as e:
        logger.warning("SHOW GRAPH TYPE failed: %s", e)
        return

    for record in show_result.records:
        type_name = str(record.get("name", ""))
        if not type_name:
            continue
        try:
            client.execute(
                f"DROP GRAPH TYPE {type_name}",
                database=scenario_ctx.current_database,
            )
            logger.debug("Dropped graph type: %s", type_name)
        except Exception as e:
            logger.warning("Failed to drop graph type %s: %s", type_name, e)


@when(
    parsers.re(
        r'login in user for USER\["(?P<user>[^"]+)"\]-PWD\["(?P<pwd>[^"]+)"\]-DB\["(?P<db>[^"]+)"\]'
    )
)
def login_in_user(
    user: str, pwd: str, db: str, bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext
):
    """以指定用户密码登录并切换到指定数据库。"""
    scenario_ctx.current_database = db
    client = bolt_pool.create_user_client(user, pwd, db)
    if user not in scenario_ctx.user_clients:
        scenario_ctx.user_clients[user] = []
    scenario_ctx.user_clients[user].append(client)
    logger.debug("Logged in as user '%s', DB '%s'", user, db)


@then(
    parsers.re(
        r'init GraphRelationship by user\["(?P<user>[^"]+)"\]-\[(?P<idx>\d+)\]-DB\["(?P<db>[^"]+)"\]'
    )
)
@when(
    parsers.re(r'init graphGQL by user\["(?P<user>[^"]+)"\]-\[(?P<idx>\d+)\]-DB\["(?P<db>[^"]+)"\]')
)
def init_graph_by_user(
    user: str, idx: str, db: str, bolt_pool: BoltConnectionPool, scenario_ctx: ScenarioContext
):
    """初始化图关系/GQL（noop 标记步骤，实际操作在前置步骤中完成）。"""
    scenario_ctx.current_database = db
    logger.debug("Init graph for user '%s', DB '%s' (noop)", user, db)


def _drop_all_constraints(client, database: str) -> None:
    """删除当前数据库中的所有约束。"""
    try:
        result = client.execute("SHOW CONSTRAINTS", database=database)
    except Exception as e:
        logger.debug("SHOW CONSTRAINTS not supported or failed: %s", e)
        return
    if not result:
        return
    for record in result.records:
        name = record.get("name", "")
        if not name:
            continue
        try:
            client.execute(f"DROP CONSTRAINT {name} IF EXISTS", database=database)
            logger.debug("Dropped constraint: %s", name)
        except Exception as e:
            logger.warning("Failed to drop constraint %s: %s", name, e)


def _drop_all_indexes(client, database: str) -> None:
    """删除当前数据库中的所有非从属、非 LOOKUP 索引。"""
    try:
        result = client.execute("SHOW INDEXES", database=database)
    except Exception as e:
        logger.debug("SHOW INDEXES not supported or failed: %s", e)
        return
    if not result:
        return
    for record in result.records:
        owning = record.get("owningConstraint")
        if owning:
            continue
        idx_type = (record.get("type") or "").upper()
        if idx_type == "LOOKUP":
            continue
        name = record.get("name", "")
        if not name:
            continue
        try:
            client.execute(f"DROP INDEX {name} IF EXISTS", database=database)
            logger.debug("Dropped index: %s", name)
        except Exception as e:
            logger.warning("Failed to drop index %s: %s", name, e)
