"""TCK 测试收集器 - UseCases 模块。

收集 features/0-original/useCases/ 下的所有 .feature 文件。
"""

from pathlib import Path

from pytest_bdd import scenarios

FEATURES_DIR = Path(__file__).resolve().parents[2] / "features" / "0-original" / "useCases"

if FEATURES_DIR.exists():
    scenarios(str(FEATURES_DIR))
