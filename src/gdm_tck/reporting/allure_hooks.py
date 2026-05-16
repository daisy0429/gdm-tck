"""Allure 报告集成钩子模块。

通过 pytest 钩子将 BDD 场景信息映射到 Allure 报告结构中。
"""

from __future__ import annotations

import logging
from pathlib import Path

import allure
import pytest

logger = logging.getLogger(__name__)


def pytest_configure(config):
    """注册 Allure 环境信息。"""
    allure_dir = config.getoption("--alluredir", default=None)
    if allure_dir is None:
        return
    # 环境信息将在 session 结束时写入
    config._allure_dir = Path(allure_dir)


def pytest_sessionfinish(session, exitstatus):
    """测试会话结束时写入 Allure 环境文件。"""
    allure_dir = getattr(session.config, "_allure_dir", None)
    if allure_dir is None:
        return
    settings = getattr(session.config, "_gdm_settings", None)
    if settings is None:
        return
    _write_environment_properties(allure_dir, settings)


def pytest_bdd_step_error(request, feature, scenario, step, step_func, step_func_args, exception):
    """BDD 步骤执行失败时附加调试信息到 Allure。"""
    allure.attach(
        f"Step: {step.keyword} {step.name}\nError: {exception}",
        name="Step Failure Detail",
        attachment_type=allure.attachment_type.TEXT,
    )


def pytest_bdd_after_scenario(request, feature, scenario):
    """场景完成后添加 Allure 标签。"""
    # Feature 名称作为 Allure Feature
    allure.dynamic.feature(feature.name)
    # Scenario 名称作为 Story
    allure.dynamic.story(scenario.name)
    # 场景标签映射为 Allure tag
    for tag in scenario.tags:
        allure.dynamic.tag(tag)


def _write_environment_properties(allure_dir: Path, settings) -> None:
    """写入 Allure environment.properties 文件。"""
    allure_dir.mkdir(parents=True, exist_ok=True)
    env_file = allure_dir / "environment.properties"
    lines = [
        f"server.mode={settings.server.mode}",
        f"server.bolt_uri={settings.server.bolt_uri}",
        f"server.database={settings.server.database}",
        f"grpc.enabled={settings.grpc.enabled}",
        f"test.tags={settings.test.tags}",
    ]
    env_file.write_text("\n".join(lines) + "\n", encoding="utf-8")
    logger.info("Allure environment written to %s", env_file)
