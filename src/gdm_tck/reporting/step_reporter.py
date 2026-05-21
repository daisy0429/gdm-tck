"""BDD 步骤级控制台报告模块。

通过 pytest-bdd 钩子在终端实时打印每个 Given/When/Then 步骤的执行状态，
支持 ANSI 颜色（绿色=通过，红色=失败）。

PyCharm 测试运行器增强：
  - 自动检测 PyCharm 环境，启用 ANSI 颜色输出
  - 右侧详情面板按步骤分行显示，每步标注 PASS / FAIL 状态
  - 失败步骤附带错误摘要，红色高亮
  - 与 PyCharm 内置测试树（左侧）联动，点击用例可查看步骤级详情

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

import os
import sys

import pytest

_GREEN = "\033[32m"
_RED = "\033[31m"
_YELLOW = "\033[33m"
_RESET = "\033[0m"
_BOLD = "\033[1m"
_DIM = "\033[2m"
_CYAN = "\033[36m"


def _is_color_enabled() -> bool:
    """检测是否应启用颜色输出。

    在以下环境中启用颜色：
    1. stdout 是 tty（真实终端）
    2. 在 PyCharm 测试运行器中运行（PYCHARM_HOSTED 环境变量）
    3. 强制启用（FORCE_COLOR 环境变量）
    """
    if os.environ.get("FORCE_COLOR"):
        return True
    if os.environ.get("PYCHARM_HOSTED"):
        return True
    return sys.stdout.isatty()


def _color(text: str, color: str) -> str:
    """为文本添加 ANSI 颜色。"""
    if not _is_color_enabled():
        return text
    return f"{color}{text}{_RESET}"


def _truncate(text: str, max_len: int = 120) -> str:
    """截断过长文本。"""
    if len(text) > max_len:
        return text[: max_len - 3] + "..."
    return text


def pytest_bdd_before_scenario(request, feature, scenario):
    """场景开始前打印场景标题。"""
    feature_label = _color(f"[{feature.name}]", _CYAN)
    print(f"\n{_BOLD}Scenario:{_RESET} {scenario.name}  {feature_label}")


def pytest_bdd_before_step(request, feature, scenario, step):
    """步骤开始前打印步骤文本（不自动换行，等待结果）。"""
    name = step.name
    if len(name) > 120:
        name = name[:117] + "..."
    prefix = f"  {step.keyword}"
    print(f"{prefix} {name} ... ", end="", flush=True)


def pytest_bdd_after_step(request, feature, scenario, step, step_func, step_func_args):
    """步骤成功后打印绿色通过标记。"""
    print(_color("✓ PASS", _GREEN))


def pytest_bdd_step_error(request, feature, scenario, step, step_func, step_func_args, exception):
    """步骤失败后打印红色失败标记和错误信息。"""
    print(_color("✗ FAIL", _RED))
    print(f"    {_color('Error:', _RED)} {exception}")
    exc_str = str(exception)
    if exc_str:
        for line in exc_str.split("\n")[1:]:
            if line.strip():
                print(f"    {_color(line, _RED)}")


def pytest_runtest_logreport(report):
    """在测试调用阶段完成后输出步骤级摘要。

    PyCharm 测试运行器会捕获 stdout 并显示在右侧面板中。
    点击左侧测试树中的用例，右侧即可看到每个步骤的执行结果。
    """
    if report.when != "call":
        return

    outcome = report.outcome
    scenario_name = report.nodeid.split("::")[-1]

    if outcome == "passed":
        status_text = _color("PASSED", _GREEN)
    elif outcome == "failed":
        status_text = _color("FAILED", _RED)
    else:
        status_text = _color(outcome.upper(), _YELLOW)

    print()
    print(f"  {status_text}  {_DIM}{scenario_name}{_RESET}")

    if outcome == "failed" and hasattr(report, "longreprtext"):
        error_lines = report.longreprtext.split("\n")
        print(f"  {_color('Failure Details:', _RED)}")
        for line in error_lines[:15]:
            if line.strip():
                print(f"    {_color(line, _RED)}")

    print()
