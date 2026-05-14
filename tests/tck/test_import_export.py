"""TCK 测试收集器 - ImportExport 模块。

收集 features/8-ImportExport/ 下的所有 .feature 文件。
"""

from pathlib import Path

from pytest_bdd import scenarios

FEATURES_DIR = Path(__file__).resolve().parents[2] / "features" / "8-ImportExport"

if FEATURES_DIR.exists() and list(FEATURES_DIR.rglob("*.feature")):
    scenarios(str(FEATURES_DIR))
