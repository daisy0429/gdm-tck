"""Steps 级 conftest - 共享 fixtures 供 step definitions 使用。"""

import pytest

from gdm_tck.connection import BoltConnectionPool
from gdm_tck.state import ScenarioContext


@pytest.fixture
def ctx(scenario_ctx: ScenarioContext) -> ScenarioContext:
    """缩写 fixture：step 函数中使用 ctx 引用场景上下文。"""
    return scenario_ctx


@pytest.fixture
def bolt(bolt_pool: BoltConnectionPool) -> BoltConnectionPool:
    """缩写 fixture：step 函数中使用 bolt 引用连接池。"""
    return bolt_pool
