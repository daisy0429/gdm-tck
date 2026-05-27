"""TCK 测试模块的 conftest.py。

提供 --features 命令行选项，支持用户指定 features/ 下的任意子路径来执行用例。
支持指定目录或单个 .feature 文件。

用法:
    uv run pytest tests/tck/ --features=0-opencypher
    uv run pytest tests/tck/ --features=0-opencypher/clauses/match
    uv run pytest tests/tck/ --features=1-metadata/Concurrent
    uv run pytest tests/tck/ --features=.
    uv run pytest tests/tck/ --features=3-Index/SecondaryIndex/01_index_node_create.feature

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
            "指定 features/ 下的子路径来执行对应用例（支持目录或单个 .feature 文件）。"
            " 例如: --features=0-opencypher, --features=1-metadata/Concurrent, "
            "--features=3-Index/SecondaryIndex/01_index_node_create.feature, --features=."
        ),
    )


def _resolve_features_path(features_arg: str) -> Path:
    if features_arg == ".":
        return FEATURES_ROOT
    return FEATURES_ROOT / features_arg


def _validate_features_path(target: Path) -> None:
    if not target.exists():
        raise pytest.UsageError(f"--features 指定的路径不存在: {target}")
    if target.is_file():
        if target.suffix != ".feature":
            raise pytest.UsageError(f"--features 指定的文件不是 .feature 文件: {target}")
    elif not any(target.rglob("*.feature")):
        raise pytest.UsageError(f"--features 指定的路径下没有 .feature 文件: {target}")


def _get_scenarios_dir(target: Path) -> Path:
    """返回应传给 scenarios() 的目录路径。

    指定目录时直接使用；指定文件时取其父目录，后续通过
    pytest_collection_modifyitems 精确过滤到该文件。
    """
    return target if target.is_dir() else target.parent


def pytest_configure(config: pytest.Config) -> None:
    features_arg = config.getoption("--features", default=None)
    if features_arg is None:
        return

    target = _resolve_features_path(features_arg).resolve()
    _validate_features_path(target)

    scenarios_dir = _get_scenarios_dir(target)
    _COLLECTOR_FILE.write_text(
        "from pathlib import Path\n"
        "from pytest_bdd import scenarios\n"
        "\n"
        f"FEATURES_DIR = Path({str(scenarios_dir)!r})\n"
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

    target = _resolve_features_path(features_arg).resolve()

    if target.is_file():
        target_file = target
    else:
        target_file = None

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
        if target_file is not None:
            if feat_path == target_file:
                kept.append(item)
            else:
                deselected.append(item)
        else:
            try:
                feat_path.relative_to(target)
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
