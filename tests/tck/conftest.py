"""TCK 测试模块的 conftest.py。

提供 --features 命令行选项，支持用户指定 features/ 下的任意子路径来执行用例。

用法:
    uv run pytest tests/tck/ --features=0-original
    uv run pytest tests/tck/ --features=0-original/clauses/match
    uv run pytest tests/tck/ --features=1-metadata/Concurrent
    uv run pytest tests/tck/ --features=.

不传 --features 时，各 test_*.py 收集器照常工作，完全向后兼容。
"""

from pathlib import Path

import pytest


FEATURES_ROOT = Path(__file__).resolve().parents[2] / "features"
_COLLECTOR_FILE = Path(__file__).resolve().parent / "_dynamic_features_collector.py"


def pytest_addoption(parser: pytest.Parser) -> None:
    parser.addoption(
        "--features",
        default=None,
        help=(
            "指定 features/ 下的子路径来执行对应用例。"
            " 例如: --features=0-original, --features=1-metadata/Concurrent, --features=."
        ),
    )


def _resolve_features_path(features_arg: str) -> Path:
    if features_arg == ".":
        return FEATURES_ROOT
    return FEATURES_ROOT / features_arg


def pytest_configure(config: pytest.Config) -> None:
    features_arg = config.getoption("--features", default=None)
    if features_arg is None:
        return

    target_dir = _resolve_features_path(features_arg).resolve()
    if not target_dir.exists():
        raise pytest.UsageError(f"--features 指定的路径不存在: {target_dir}")
    if not any(target_dir.rglob("*.feature")):
        raise pytest.UsageError(f"--features 指定的路径下没有 .feature 文件: {target_dir}")

    _COLLECTOR_FILE.write_text(
        "from pathlib import Path\n"
        "from pytest_bdd import scenarios\n"
        "\n"
        f"FEATURES_DIR = Path({str(target_dir)!r})\n"
        "\n"
        "if FEATURES_DIR.exists() and list(FEATURES_DIR.rglob('*.feature')):\n"
        "    scenarios(str(FEATURES_DIR))\n"
    )


def pytest_collection_modifyitems(
    session: pytest.Session, config: pytest.Config, items: list[pytest.Item]
) -> None:
    features_arg = config.getoption("--features", default=None)
    if features_arg is None:
        return

    target_dir = _resolve_features_path(features_arg).resolve()

    kept: list[pytest.Item] = []
    deselected: list[pytest.Item] = []
    for item in items:
        scenario = (
            getattr(item.function, "__scenario__", None) if hasattr(item, "function") else None
        )
        if scenario is None:
            kept.append(item)
            continue
        feat_path = Path(scenario.feature.filename).resolve()
        try:
            feat_path.relative_to(target_dir)
            kept.append(item)
        except ValueError:
            deselected.append(item)

    if deselected:
        config.hook.pytest_deselected(items=deselected)
    items[:] = kept


def pytest_sessionfinish(session: pytest.Session, exitstatus: int) -> None:
    if _COLLECTOR_FILE.exists():
        try:
            _COLLECTOR_FILE.unlink()
        except OSError:
            pass
