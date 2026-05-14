"""TCK 测试收集器 - 国标合规测试模块。

收集 features/6-NationalStandard/ 下的所有 .feature 文件。
"""

from pathlib import Path

from pytest_bdd import scenarios

FEATURES_DIR = Path(__file__).resolve().parents[2] / "features" / "6-NationalStandard"

if FEATURES_DIR.exists() and list(FEATURES_DIR.rglob("*.feature")):
    scenarios(str(FEATURES_DIR))
