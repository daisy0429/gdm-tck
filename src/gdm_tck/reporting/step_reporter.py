"""BDD 步骤级控制台报告模块。

通过 pytest-bdd 钩子在终端实时打印每个 Given/When/Then 步骤的执行状态，
支持 ANSI 颜色（绿色=通过，红色=失败）。

效果示例::

    Scenario: Match all nodes
      Given test data exists: ... ✓ PASS
      When executing query: ... ✓ PASS
      Then the result should be, in any order: ... ✓ PASS

    Scenario: Match with filter
      Given test data exists: ... ✓ PASS
      When executing query: ... ✗ FAIL
        Error: Result mismatch...
"""

from __future__ import annotations

import sys

import pytest

# ANSI 颜色码
_GREEN = "\033[32m"
_RED = "\033[31m"
_RESET = "\033[0m"
_BOLD = "\033[1m"


def _is_color_enabled() -> bool:
    """检测终端是否支持颜色输出。"""
    return sys.stdout.isatty()


def _color(text: str, color: str) -> str:
    """为文本添加 ANSI 颜色（仅在支持颜色的终端）。"""
    if not _is_color_enabled():
        return text
    return f"{color}{text}{_RESET}"


def pytest_bdd_before_scenario(request, feature, scenario):
    """场景开始前打印场景标题。"""
    print(f"\n{_BOLD}Scenario: {scenario.name}{_RESET}")


def pytest_bdd_before_step(request, feature, scenario, step):
    """步骤开始前打印步骤文本（不自动换行，等待结果）。"""
    prefix = f"  {step.keyword}"
    # 步骤名称可能很长，截断显示以保持可读性
    name = step.name
    if len(name) > 120:
        name = name[:117] + "..."
    print(f"{prefix} {name} ... ", end="", flush=True)


def pytest_bdd_after_step(request, feature, scenario, step, step_func, step_func_args):
    """步骤成功后打印绿色通过标记。"""
    print(_color("✓ PASS", _GREEN))


def pytest_bdd_step_error(request, feature, scenario, step, step_func, step_func_args, exception):
    """步骤失败后打印红色失败标记和错误信息。"""
    print(_color("✗ FAIL", _RED))
    print(f"    {_color('Error:', _RED)} {exception}")
    # 打印断言错误的详细上下文
    exc_str = str(exception)
    if exc_str:
        for line in exc_str.split("\n")[1:]:
            if line.strip():
                print(f"    {_color(line, _RED)}")
