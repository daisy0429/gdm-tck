"""TCK 测试收集器 - Charset 模块。

收集 features/7-Charset/ 下的所有 .feature 文件。
"""

from pathlib import Path

from pytest_bdd import scenarios

FEATURES_DIR = Path(__file__).resolve().parents[2] / "features" / "7-Charset"

if FEATURES_DIR.exists() and list(FEATURES_DIR.rglob("*.feature")):
    scenarios(str(FEATURES_DIR))
