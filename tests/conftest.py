"""顶层 conftest.py - Session 级 fixtures。

提供全局配置加载、Bolt 连接池、Allure 环境信息等会话级资源。
"""

import logging

import pytest

# 注册所有 step definitions 和 reporting 钩子（必须在顶层 conftest 中定义）
pytest_plugins = [
    "steps.step_graph_init",
    "steps.step_query_exec",
    "steps.step_result_assert",
    "steps.step_plan_assert",
    "steps.step_error_assert",
    "steps.step_side_effects",
    "steps.step_parameters",
    "steps.step_schema_assert",
    "gdm_tck.reporting.allure_hooks",
    "gdm_tck.reporting.step_reporter",
]

from gdm_tck.config import load_settings, Settings
from gdm_tck.connection import BoltConnectionPool
from gdm_tck.parser_patch import apply_patch as _apply_parser_patch
from gdm_tck.state import ScenarioContext

_apply_parser_patch()

logger = logging.getLogger(__name__)


def pytest_configure(config):
    """pytest 配置钩子：初始化日志。"""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )


_SKIP_MARKERS = {
    "skip_bug": "Skipped due to known product bug",
    "skip_script": "Skipped due to test script issue",
    "ignore": "Skipped",
}


def pytest_collection_modifyitems(config, items):
    """根据 marker 自动跳过标记了 skip_bug / skip_script / ignore 的用例。"""
    for item in items:
        for marker_name, default_reason in _SKIP_MARKERS.items():
            marker = item.get_closest_marker(marker_name)
            if marker is not None:
                reason = marker.kwargs.get(
                    "reason", marker.args[0] if marker.args else default_reason
                )
                item.add_marker(pytest.mark.skip(reason=reason))
                break


@pytest.fixture(scope="session")
def settings() -> Settings:
    """加载全局配置（会话级）。"""
    return load_settings()


@pytest.fixture(scope="session")
def bolt_pool(settings: Settings) -> BoltConnectionPool:
    """创建并连接 Bolt 连接池（会话级）。

    在整个测试会话中共享连接，测试结束后自动关闭。
    """
    pool = BoltConnectionPool(settings)
    pool.connect_all()
    yield pool
    pool.close_all()


@pytest.fixture
def scenario_ctx(settings: Settings) -> ScenarioContext:
    """创建场景状态容器（每个测试函数独立实例）。

    每次测试/场景开始时提供全新的状态容器，
    确保场景间完全隔离。
    """
    ctx = ScenarioContext(current_database=settings.server.database)
    yield ctx
    ctx.reset()
